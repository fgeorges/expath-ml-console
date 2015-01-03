# Developer guide

## Architecture

Each app server can have its own repo.  The components installed in
the repo are registered in MarkLogic, so importing modules do not have
to give an "at hint".

The repo is always located in the directory `expath-repo` under the
modules root (either the root under the modules database, or in the
modules directory).

## Location resolution in MarkLogic 7

SVC-FILOPN
