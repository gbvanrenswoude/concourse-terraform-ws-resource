## Implementing a Resource

A resource type is implemented by a container image with three scripts:

    /opt/resource/check for checking for new versions of the resource
    /opt/resource/in for pulling a version of the resource down
    /opt/resource/out for idempotently pushing a version up

Distributing resource types as containers allows them to package their own dependencies. For example, the Git resource comes with git installed.

All resources must implement all three actions, though the actions can just be no-ops (which still must be correctly implemented as detailed below).

Resources can emit logs to the user by writing to stderr. ANSI escape codes (coloring, cursor movement, etc.) will be interpreted properly by the web UI, so you should make your output pretty.


### check: Check for new versions.

A resource type's check script is invoked to detect new versions of the resource. It is given the configured source and current version on stdin, and must print the array of new versions, in chronological order, to stdout, including the requested version if it's still valid.

The request body will have the following fields:
1. `source` is an arbitrary JSON object which specifies the location of the resource, including any credentials. This is passed verbatim from the resource configuration.  
For git this would be the repo URI, which branch, and a private key if necessary.

2.    `version` is a JSON object with string fields, used to uniquely identify an instance of the resource. For git this would be a commit SHA.  
This will be omitted from the first request, in which case the resource should return the current version (not every version since the resource's inception).

For example, here's what the input for a git resource may look like:
```
{
  "source": {
    "uri": "git://some-uri",
    "branch": "develop",
    "private_key": "..."
  },
  "version": { "ref": "61cebf" }
}
```
Upon receiving this payload the git resource would probably do something like:
```
[ -d /tmp/repo ] || git clone git://some-uri /tmp/repo
cd /tmp/repo
git pull && git log 61cbef..HEAD
```
Note that it conditionally clones; the container for checking versions is reused between checks, so that it can efficiently pull rather than cloning every time.

And the output, assuming d74e01 is the commit immediately after 61cbef:
```
[
  { "ref": "61cbef" },
  { "ref": "d74e01" },
  { "ref": "7154fe" }
]
```
The list may be empty, if there are no versions available at the source. If the given version is already the latest, an array with that version as the sole entry should be listed.

If your resource is unable to determine which versions are newer then the given version (e.g. if it's a git commit that was push -fed over), then the current version of your resource should be returned (i.e. the new HEAD).

### in: Fetch a given resource.

The in script is passed a destination directory as command line argument $1, and is given on stdin the configured source and a precise version of the resource to fetch.

The script must fetch the resource and place it in the given directory.

If the desired resource version is unavailable (for example, if it was deleted), the script must error.

The script must emit the fetched version, and may emit metadata as a list of key-value pairs. This data is intended for public consumption and will make it upstream, intended to be shown on the build's page.

The request will contain the following fields:

1.    `source` is the same value as passed to check.

2.    `version` is the same type of value passed to check, and specifies the version to fetch.

3.    `params` is an arbitrary JSON object passed along verbatim from params on a get step.

Example request, in this case for the git resource:
```
{
  "source": {
    "uri": "git://some-uri",
    "branch": "develop",
    "private_key": "..."
  },
  "version": { "ref": "61cebf" }
}
```
Upon receiving this payload the git resource would probably do something like:
```
git clone --branch develop git://some-uri $1
cd $1
git checkout 61cebf
```
And output:
```
{
  "version": { "ref": "61cebf" },
  "metadata": [
    { "name": "commit", "value": "61cebf" },
    { "name": "author", "value": "Hulk Hogan" }
  ]
}
```


### out: Update a resource.

The out script is called with a path to the directory containing the build's full set of sources as the first argument, and is given on stdin the configured params and the resource's source configuration.

The script must emit the resulting version of the resource. For example, the git resource emits the sha of the commit that it just pushed.

Additionally, the script may emit metadata as a list of key-value pairs. This data is intended for public consumption and will make it upstream, intended to be shown on the build's page.

The request will contain the following fields:

1.    `source` is the same value as passed to check.

2.    `params` is an arbitrary JSON object passed along verbatim from params on a put step.

Example request, in this case for the git resource:
```
{
  "params": {
    "branch": "develop",
    "repo": "some-repo"
  },
  "source": {
    "uri": "git@...",
    "private_key": "..."
  }
}
```
Upon receiving this payload the git resource would probably do something like:
```
cd $1/some-repo
git push origin develop
```
And output:
```
{
  "version": { "ref": "61cebf" },
  "metadata": [
    { "name": "commit", "value": "61cebf" },
    { "name": "author", "value": "Mick Foley" }
  ]
}
```

### Metadata

When used in a get step or a put step, metadata about the running build is made available via the following environment variables:

$BUILD_ID

    The internal identifier for the build. Right now this is numeric but it may become a guid in the future. Treat it as an absolute reference to the build.
$BUILD_NAME

    The build number within the build's job.
$BUILD_JOB_NAME

    The name of the build's job.
$BUILD_PIPELINE_NAME

    The pipeline that the build's job lives in.
$BUILD_TEAM_NAME

    The team that the build belongs to.
$ATC_EXTERNAL_URL

    The public URL for your ATC; useful for debugging.

If the build is a one-off, $BUILD_NAME, $BUILD_JOB_NAME, and $BUILD_PIPELINE_NAME will not be set.

None of these variables are available to /check.

These variables should be used solely for annotating things with metadata for traceability, i.e. for linking to the build in an alert or annotating an automated commit so its origin can be discovered.

They should not be used to emulate versioning (e.g. by using the increasing build number). They are not provided to task steps to avoid this anti-pattern.

### Certificate Propagation

Certificates can be automatically propagated into each resource container, if the worker is configured to do so. The BOSH release configures this automatically, while the concourse binary must be given a --certs-dir flag pointing to the path containing the CA certificate bundle.

The worker's certificate directory will then be always mounted at /etc/ssl/certs, read-only, in each resource container created on the worker. There's no single standard path for this so we picked one that would work out of the box in most cases.

This approach to certificate configuration is similar in mindset to the propagation of http_proxy/https_proxy - certs are kind of a baseline assumption when deploying software, so Concourse should do its best to respect it out-of-the-box, especially as they're often used in tandem with a man-in-the-middle corporate SSL proxy. (In this way it doesn't feel too much like the anti-pattern of hand-tuning workers.)
