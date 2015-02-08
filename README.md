expath-ml-console
=================

EXPath Console for MarkLogic.

Installation
------------

- Create a new HTTP server in the MarkLogic admin console.
- Put the source code of the Console at the root of the App Server
  (depending on the options you selected creating the App Server, it
  could be on its modules database or on the filesystem if you decided
  to store the modules of this App Server on the filesystem).
- Make sure to set the app server URL rewriter field (at the end of
  the admin console page for the app server) to the value
  `/plumbing/rewriter.xq` the document database linked to the HTTP
  server will not be used by the Console.

The document database linked to the HTTP server will not be used by
the EXPath Console for MarkLogic.
