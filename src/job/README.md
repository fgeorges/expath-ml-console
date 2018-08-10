# Jobs

The lifecycle of a new job is as follow:

- `created`
- `ready`
- `started`
- either `success` or `failure`

## Create

When created, a job is assigned a new ID and dedicated collection.  A document
is created for the job (either XML or JSON).  Two module documents (either
XQuery or JavaScript) are also created in the same collection, and linked from
the job document: the init code and the exec code.

The modules have a code by default, make sure to edit them before initializing a
job and further to execute its tasks.

## Init

Once a job has been created, one can initialize it.  Essentially that means
creating its tasks by evaluating its init module.

The result of the init module must be a sequence (in XQuery) or an array (in
JavaScript).  Each item in the sequence (resp. array) becomes a task.  The item
itself is called the "chunk"

For each chunk, a task document is created.  A task document is in the
collection of its job.  It contains the chunk itself (therefore, a chunk cannot
contain items like functions.)

If a chunk, as returned by the init module, is a map (for XQuery) or an object
containing a property `chunk` (for JavaScript), then the entry `chunk` becomes
the chunk to be saved.  The entry `label` (if any) becomes the label of the task
(used e.g. for displaying it in the Console UI.)

TODO: Other properties could be set on the chunk?

TODO: Allow an XML element with a child "chunk" (like an object in SJS)?

TODO: Actually impose such a format? (an init module must return a "list" of
elements c:chunk (or map) or objects { chunk: }, etc.) => nop.  Possible if
wanted/needed, but must be dead simple for people wanting it dead simple.

## Exec

TODO: ...

TODO: How to report an error?  How to set what to save in the task doc?  How to
say "continue", "stop", "success", etc.?  Ability to put "warnings" (like, look
at me, I got intersting messages, but I am not an error per se)

TODO: Also impose a specific format for the return value? (not impose, see
above, but yeah, allow).
