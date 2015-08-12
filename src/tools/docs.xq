xquery version "3.0";

(:~
 : The document manager page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   let $db-options := local:database-options()
   return
      <wrapper>
         <p>Some tools to insert and delete documents.</p>
         <h4>Upload files</h4>
         <p>Standard multiple files upload area...</p>
         <form id="fileupload" action="doc-upload" method="POST" enctype="multipart/form-data">
            <input type="file" name="files" multiple="true"/>
            <input type="submit"/>
         </form>
         <p>New jQuery File Upload plugin test area...</p>
         <form id="fileupload" action="doc-upload" method="POST" enctype="multipart/form-data">
            <input type="file" name="files[]" multiple="true"/>
            <input type="submit"/>
         </form>
         <p>New Dropzone.js test area...</p>
         <form action="doc-upload"
               class="dropzone"
               id="dropzone"/>

    <div id="actions" class="row">
      <div class="col-lg-7">
        <!-- The fileinput-button span is used to style the file input field as button -->
        <span class="btn btn-success fileinput-button">
            <i class="glyphicon glyphicon-plus"></i>
            <span>Add files...</span>
        </span>
        <button type="submit" class="btn btn-primary start">
            <i class="glyphicon glyphicon-upload"></i>
            <span>Start upload</span>
        </button>
        <button type="reset" class="btn btn-warning cancel">
            <i class="glyphicon glyphicon-ban-circle"></i>
            <span>Cancel upload</span>
        </button>
      </div>
      <div class="col-lg-5">
        <!-- The global file processing state -->
        <span class="fileupload-process">
          <div id="total-progress" class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
            <div class="progress-bar progress-bar-success" style="width:0%;" data-dz-uploadprogress=""></div>
          </div>
        </span>
      </div>
    </div>

    <div class="table table-striped files" id="previews">
      <div id="template" class="file-row">
        <!-- This is used as the file preview template -->
        <div>
            <span class="preview"><img data-dz-thumbnail=""/></span>
        </div>
        <div>
            <p class="name" data-dz-name=""></p>
            <strong class="error text-danger" data-dz-errormessage=""></strong>
        </div>
        <div>
            <p class="size" data-dz-size=""></p>
            <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
              <div class="progress-bar progress-bar-success" style="width:0%;" data-dz-uploadprogress=""></div>
            </div>
        </div>
        <div>
          <button class="btn btn-primary start">
              <i class="glyphicon glyphicon-upload"></i>
              <span>Start</span>
          </button>
          <button data-dz-remove="" class="btn btn-warning cancel">
              <i class="glyphicon glyphicon-ban-circle"></i>
              <span>Cancel</span>
          </button>
          <button data-dz-remove="" class="btn btn-danger delete">
            <i class="glyphicon glyphicon-trash"></i>
            <span>Delete</span>
          </button>
        </div>
      </div>
    </div>

    <script>
<![CDATA[
      // Get the template HTML and remove it from the doument
      var previewNode = document.querySelector("#template");
      previewNode.id = "";
      var previewTemplate = previewNode.parentNode.innerHTML;
      previewNode.parentNode.removeChild(previewNode);

      var myDropzone = new Dropzone(document.body, { // Make the whole body a dropzone
        url: "http://www.torrentplease.com/dropzone.php", // Set the url
        thumbnailWidth: 80,
        thumbnailHeight: 80,
        parallelUploads: 20,
        previewTemplate: previewTemplate,
        autoQueue: false, // Make sure the files aren't queued until manually added
        previewsContainer: "#previews", // Define the container to display the previews
        clickable: ".fileinput-button" // Define the element that should be used as click trigger to select files.
      });

      myDropzone.on("addedfile", function(file) {
        // Hookup the start button
        file.previewElement.querySelector(".start").onclick = function() { myDropzone.enqueueFile(file); };
      });

      // Update the total progress bar
      myDropzone.on("totaluploadprogress", function(progress) {
        document.querySelector("#total-progress .progress-bar").style.width = progress + "%";
      });

      myDropzone.on("sending", function(file) {
        // Show the total progress bar when upload starts
        document.querySelector("#total-progress").style.opacity = "1";
        // And disable the start button
        file.previewElement.querySelector(".start").setAttribute("disabled", "disabled");
      });

      // Hide the total progress bar when nothing's uploading anymore
      myDropzone.on("queuecomplete", function(progress) {
        document.querySelector("#total-progress").style.opacity = "0";
      });

      // Setup the buttons for all transfers
      // The "add files" button doesn't need to be setup because the config
      // `clickable` has already been specified.
      document.querySelector("#actions .start").onclick = function() {
        myDropzone.enqueueFiles(myDropzone.getFilesWithStatus(Dropzone.ADDED));
      };
      document.querySelector("#actions .cancel").onclick = function() {
        myDropzone.removeAllFiles(true);
      };
]]>
    </script>

         <h4>Insert a document</h4>
         <p>Insert a file at some specific place into a specific database. By
            default the file is expected to be XML, but you can change its type to
            text or binary. If the file already exists, it is overriden.</p>
         <form method="post" action="insert" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target file:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>File to insert:</span>
            <input type="file" name="file"/>
            <br/>
            <span>Format of the file:</span>
            <select name="format">
               <option value="xml">XML</option>
               <option value="text">Text</option>
               <option value="binary">Binary</option>
            </select>
            <br/>
            <input type="checkbox" name="override" value="true"/>
            <span>Override the target URI if it already exists in the database.</span>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Insert a directory</h4>
         <p>Insert a directory recursively at some specific place into a
            specific database.  The optional filters are regex expressions (like
            "2012-03-[0-9]+\.xml" for instance). This requires the directory to
            be on the same machine as MarkLogic itself, and the path to be
            absolute. It is an error if the directory already exists in the
            database.</p>
         <p>The set of files to include is computed as following: first we
            start with all the files in the directory, including all of its
            descendants. If the include filter is provided, only the file with
            the filename matching the filter are included, all the other files
            are discarded (the match is done over the filename only, after the
            last '/', also for directories). If the exclude filter is provided,
            the set of selected files is further restricted by getting rid of
            the files matching the filter.</p>
         <form method="post" action="insert" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target directory:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>Directory to insert:</span>
            <input type="text" name="dir" size="50"/>
            <br/>
            <span>Include filter:</span>
            <input type="text" name="include" size="25"/>
            <br/>
            <span>Exclude filter:</span>
            <input type="text" name="exclude" size="25"/>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Insert a zipped directory</h4>
         <p>Insert a directory based on a ZIP file. The ZIP file is expanded to
            create the content of the directory on the database. It is an error
            if the directory already exists in the database.</p>
         <form method="post" action="insert" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target directory:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>ZIP to insert:</span>
            <input type="file" name="zipdir"/>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Delete a document</h4>
         <p>Delete a document from a database. It is an error if there is no
            such document in the database.</p>
         <form method="post" action="delete" enctype="multipart/form-data">
            <span>Database:</span>
            { $db-options }
            <br/>
            <span>Document:</span>
            <input type="text" name="doc" size="50"/>
            <br/>
            <input type="submit" value="Delete"/>
         </form>
         <h4>Delete a directory</h4>
         <p>Delete a directory entirely from a database. It is an error if there
            is no such directory in the database.</p>
         <form method="post" action="delete" enctype="multipart/form-data">
            <span>Database:</span>
            { $db-options }
            <br/>
            <span>Directory:</span>
            <input type="text" name="dir" size="50"/>
            <br/>
            <input type="submit" value="Delete"/>
         </form>
      </wrapper>/*
};

(:~
 : TODO: ...
 : TODO: Duplicated in tools.xq, factorize out!
 :)
declare function local:database-options()
{
   <select name="database"> {
      for $db in a:get-databases()/a:database
      order by $db/a:name
      return
         <option value="{ $db/@id }">{ $db/fn:string(a:name) }</option>
   }
   </select>
};

v:console-page('../', 'tools', 'Document manager', local:page#0)
