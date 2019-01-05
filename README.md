# dropbox-shares
Ruby script for listing all the shared folders for a Dropbox account.

Since Dropbox no longer lists all of your shared folders via the web browser, I've put together a Ruby script that lets you list them using the Dropbox API v2.

In order to use the Dropbox API you need to first create an app via the Developer section of the Dropbox site.
Once you have created an app you can generate an access token that you can use with this script.

Store the access token in an environment variable called DROPBOX_ACCESS_TOKEN.

## Usage

The following options can be used when running the script:

~~~~
-w, --with=[NAME]                Filter folders shared with users named
-o, --[no-]owner                 Shares you are owner of
-v, --[no-]viewer                Shares you are viewer of
-e, --[no-]editor                Shares you are editor of
-u, --[no-]unmounted             Include unmounted shares
-m, --[no-]mounted               Include mounted shares
    --[no-]verbose               Run verbosely
-h, --help                       Show this message
    --version                    Show version
~~~~

If none of the access type flags are set then defaults to showing all.
If neither -u or -m flags are set then defaults to showing all.
