<cfsilent><cfsetting showdebugoutput="no">
<!---  
*********************
Author: Michael A. Gillespie
NetGains by design, LLC
spidre@gmail.com
@spidre409
*********************
The MIT License (MIT)

Copyright (c) [2014] [NetGains by design, LLC - Michael A. Gillespie]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

All that said, if you like it, it saved you time and you think its worth it, send me an interesting
T-Shirt - Mens, XL.  PO Box 185, Santa Fe TX  77510.
--->

<cfscript>
// use of this file requires a POST, not a GET request

// set some vars for redactor
scoop=structnew(); //struct for all input params
work=structnew(); /// hold the work time vars
plop=structnew(); // output keys go here "filelink (url to img) or error(short message),errorDetail(Long error message)
scoop.mediaField="file"; // this is the redactor default upload field name defined in js as imageUploadParam
scoop.maxsize=640; //set to zero to ignore resize routine, otherwise this will limit the size of the image to this width
scoop.uploadPath=expandPath("../")&"img\";  // server file path to public image folder
scoop.uploadPathTMP=scoop.uploadPath&"staging\";  // server file path to TMP folder where file is validated before making public - typically outside of web root
scoop.imgURL="/img/"; // url to image - relative URL OK
scoop.okImages="gif,jpg,jpeg,png"; // allowed image types
scoop.convertImg=false; // if true will convert all uploaded images to filetype on next line
scoop.convertTo="png"; // only used if converImg=true.  Must be one of the file types in okImages
scoop.createJSONforLibrary=true; // if true, after successful upload, JSON file will be created to use with media library
scoop.JSONfileName="images.json"; // the filename for the media library to be written to
scoop.overWriteImage=false; // DOH!
</cfscript>
<cftry>
<!--- don't allow get access --->
<cfif not structkeyexists(form,"fieldnames")>
	<cfthrow errorcode="418" message="Implementation Error" detail="Unable to process request, check documentation for correct implementation">
</cfif>
<!--- make sure the upload field is configured both places correctly --->
<cfif not structkeyexists(form,scoop.mediaField)>
	<cfthrow errorcode="412" message="Implementation Error" detail="The upload field #scoop.mediaField# has not been configured in Redactor. Update the imageUploadParam in the redactor.js file to match the mediaField setting in this processor.">
</cfif>
<!--- create folder if it does not exist --->
<cfif not directoryExists(scoop.uploadPath)>
	<cfdirectory action="create" directory="#scoop.uploadPath#">
</cfif>
<cfif not directoryExists(scoop.uploadPathTMP)>
	<cfdirectory action="create" directory="#scoop.uploadPathTMP#">
</cfif>
<!--- upload the pic to the temp folder for processing --->
	<cffile action="upload"
	   filefield="#scoop.mediaField#"
	   destination="#scoop.uploadPathTMP#"
	   nameconflict="overwrite">
<cfset work.theFile=cffile.serverFile>
<cfset work.fileName=cffile.serverFileName>
<cfset work.fileExtension=cffile.serverFileExt>
<cfset work.newFile=work.theFile>
<!--- is it an image? --->
<!--- since mime-type determination is a BROWSER function, lets rely on the server side to determine if it is an image --->
<cfset isAnImageFile=isImageFile("#scoop.uploadPathTMP##work.theFile#")>
<cfif not isAnImageFile>
	<cfif fileexists("#scoop.uploadPathTMP##work.theFile#")>
		<cffile action="delete" file="#scoop.uploadPathTMP##work.theFile#">
	</cfif>
	<cfthrow errorcode="403" message="Upload File is not an image" detail="Only image files can be uploaded">
</cfif>
<!--- Server says it is an image, is it one of the types of files that we are allowing? --->
<cfif listfindnocase(scoop.okImages,work.fileExtension) lt 1>
	<cfif fileexists("#scoop.uploadPathTMP##work.theFile#")>
		<cffile action="delete" file="#scoop.uploadPathTMP##work.theFile#">
	</cfif>
	<cfthrow errorcode="403" message="File Type not allowed" detail="Only image files of the following types can be uploaded: #scope.okFiles#">
</cfif>

<!--- OK, now that we have taken care of the common errors, lets work on that image --->
<!--- read the tmp image into memory --->
<cfimage action="read" name="work.tmpImg" source="#scoop.uploadPathTMP##work.theFile#" >
<!--- get the info about the image --->
<cfset work.tmpImgInfo=imageInfo(work.tmpImg)>
<!--- lets see if we need to resize this thing --->
<cfif val(scoop.maxSize) gt 0 AND (work.tmpImgInfo.height gt scoop.maxSize or work.tmpImgInfo.width gt scoop.maxSize)>
	<!--- resize it --->
	<cfset ImageScaleToFit(work.tmpImg,val(scoop.maxSize),val(scoop.maxSize))>
</cfif>
<!--- convert it if requested --->
<cfif scoop.convertImg>
	<cfset work.newFile="#work.fileName#.#work.fileExtension#">
</cfif>
<!--- write the file to the public folder --->
<cfset imageWrite(work.tmpImg,"#scoop.uploadPath##work.newFile#")>
<!--- Clean up the mess, sometimes CF locks the file if the server updates are not current: see hf801-71557 to fix it --->
<cfif fileexists("#scoop.uploadPathTMP##work.theFile#")>
	<cftry>
		<cffile action="delete" file="#scoop.uploadPathTMP##work.theFile#">
		<cfcatch><!--- catch it and ignore it; it is just a junk file ---></cfcatch>
	</cftry>
</cfif>
<!--- finally, set the filelink to be returned --->
<cfset plop.filelink=scoop.imgURL&work.theFile>
<!--- if requested, create the JSON file to be used with the media library in redactor 
		This routine will make sure the thumbs folder exists and create it if not
		next it will make sure each image has a thumb
		next it will delete thumbs that do not have images
		finally it will write the JSON file into the main image folder
--->
<cfif scoop.createJSONforLibrary>
	<cfset forJSONoutput=arraynew(1)>
	<cfif not directoryExists("#scoop.uploadPath#thumbs\")>
		<cfdirectory action="create" directory="#scoop.uploadPath#thumbs\">
	</cfif>
	<!--- get the list of images --->
	<cfdirectory directory="#scoop.uploadPath#" action="list" name="work.imageList" recurse="no" listinfo="Name" type="File">
	<!--- loop and see if there are thumbs for all --->
	<cfoutput query="work.imageList">
		<cfif listcontainsnocase(scoop.okImages,listlast(work.imageList.name,"."))>
			<cfif not fileexists("#scoop.uploadPath#thumbs\#work.imageList.name#")>
				<cfimage action="read" name="work.tmpImgT" source="#scoop.uploadPath##work.imageList.name#" >
				<cfset ImageScaleToFit(work.tmpImgT,100,75,"mediumQuality")>
				<cfset imageWrite(work.tmpImgT,"#scoop.uploadPath#thumbs\#work.imageList.name#")>
			</cfif>
		</cfif>
	</cfoutput>
	<!--- now, remove any thumbs that don't  have bigs --->
	<cfdirectory directory="#scoop.uploadPath#thumbs\" action="list" name="work.thumbList" recurse="no" listinfo="Name" type="File">
	<cfoutput query="work.thumblist">
		<cfif not fileexists("#scoop.uploadPath##work.thumbList.name#")>
			<cffile action="delete" file="#scoop.uploadPath#thumbs\#work.thumbList.name#"> 
		<cfelse>
			<!--- add the data to the stuct and append to array --->
			<!--- { "thumb": "json/images/1_m.jpg", "image": "json/images/1.jpg", "title": "Image 1", "folder": "Folder 1" } --->
			<cfset thisPosition=structnew()>
			<cfset thisPosition.thumb=scoop.imgURL&"thumbs/"&work.thumbList.name>
			<cfset thisPosition.image=scoop.imgURL&work.thumbList.name>
			<cfset thisposition.title="Click to Insert">
			<cfset thisPosition.folder="Upload Images"> 
			<cfset arrayAppend(forJSONoutput,thisPosition)>
		</cfif>
	</cfoutput>
	<cfset outFileData=replace(replace(replace(replace(replace(serializeJSON(forJSONoutput),"\","","all"),'"TITLE"','"title"','all'),'"IMAGE"','"image"','all'),'"FOLDER"','"folder"','all'),'"THUMB"','"thumb"','all')>
	<cffile action="write" addnewline="no" file="#scoop.uploadPath##scoop.JSONfileName#" output="#outFileData#" fixnewline="no">
</cfif>
<cfcatch type="any">
	<cfset plop.error=cfcatch.Message>
	<cfset plop.errorDetail=cfcatch.detail>
</cfcatch>
</cftry>
</cfsilent><cfoutput>#lcase(replace(serializeJSON(plop),"\","","all"))#</cfoutput><cfabort>
