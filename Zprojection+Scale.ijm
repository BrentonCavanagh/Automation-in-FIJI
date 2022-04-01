/*
 * Script written by Brenton Cavanagh 2018 brentoncavanagh@rcsi.ie
 * Purpose: To open and resave user choosen filetype as a tiff from 
 * all subfolders. Output to a single folder. Z Stacks are projected; 
 * Option to also add scalebar and save as RGB tiff.
 */
 
// Script updated: 2022-03-02
 
//Generate user input
#@ File (label="Input Folder",description="Location of images you want to process", style="directory") dirIN
#@ File (label="Save Location",description="Location to save processed images", style="directory") dirOUT
#@ String (label="Input file type", description="Input filetype you want to process", choices={".lsm",".tif",".nd",".nd2",".zvi",".czi"}, value=".lsm") fileType
#@ String (label="Use Default or Bioformats for file import", description="Allows the selection of native FIJI or Bioformats as file importer", choices={"Default","BioFormats"}, style="radioButtonHorizontal", value="Default") importer
#@ Boolean (label="Auto-adjust brightness", description="Will automaticlly brighten all images?") addBright
#@ Boolean (label="Create RGB image with scalebar", description="Creates a flattened image with a scalebar") addScale
#@ String (label="RGB image file format", description="Format for RGB image generated. note: PNG is slower!", choices={"tif","png"}, value=".tif") prvType

setBatchMode(true);
count = 0;
listFiles(dirIN);

//loop to find all files; including in subfolders
function listFiles(dirIN) {
     list = getFileList(dirIN);
     print(dirIN, dirOUT);
     for (i=0; i<list.length; i++) {
        current = list[i];
        if (endsWith(list[i], "/")){
           listFiles(""+dirIN+File.separator+list[i]);
        }
        else{
	        ProcessFile(dirIN, dirOUT);
	    }
	}
print(" ");
}

//Main function to open files for processing
function ProcessFile(dirIN, dirOUT){
	filename =  dirIN+File.separator+current; 
	if (endsWith(filename, fileType)){
    	//Chooses file reader here is
    	if (importer == "Default"){
    	    	open(filename);
    	    	name = File.nameWithoutExtension;
    	}
    	else {
    		run("Bio-Formats Importer", "open=["+filename+"] color_mode=Default view=Hyperstack");
    		name1 = File.nameWithoutExtension;
    		name = substring(name1, 1); //biotformats add a / for some reason to file name hacky fix for this
    	}
	 	//get some file details and set savename
	 	getDimensions(width, height, channels, slices, frames);
	 	getPixelSize(unit, pixelWidth, pixelHeight);
	 	savename =  dirOUT+File.separator+name;
		
		//Process 1D Image
		if (slices==1 && channels==1){
			print("1D image " + filename);
			if (addBright == true){
				resetMinAndMax();
				run("Enhance Contrast", "saturated=0.35");
				saveAs("tiff", savename);
			}
			else{
				saveAs("tiff", savename);
			}
			if (addScale == true){
				addScalebar(width, height, pixelWidth, prvType);
				}
			
			close();
		}
		//Process multichannel image
		if (slices==1 && channels>1){
			print("2D image " + filename);
			run("Make Composite");
			if (addBright == true){
				brighten(channels);
				saveAs("tiff", savename);
			}
			else{
				saveAs("tiff", savename);
			}
			if (addScale == true){
				addScalebar(width, height, pixelWidth, prvType);
				}
			close();
		}
		//Process 1 channel Zstack
		if (slices>1 && channels==1){
			print("3D Image " + filename);
			run("Z Project...", "start=1 stop"+slices+" projection=[Max Intensity]");
			if (addBright == true){
				run("Enhance Contrast", "saturated=0.35");
				saveAs("tiff", savename);
			}
			else{
				saveAs("tiff", savename);
			}
			if (addScale == true){
				addScalebar(width, height, pixelWidth, prvType);
				}
			
			run("Close All");
		}
		//Process multichannel Zstack
		if (slices>1 && channels>1){
			print("3D Image " + filename);
			run("Make Composite");
			run("Z Project...", "start=1 stop"+slices+" projection=[Max Intensity]");
			savename =  dirOUT+File.separator+"MAX_"+name;
			if (addBright == true){
				getDimensions(width, height, channels, slices, frames);
				brighten(channels);
				saveAs("tiff", savename);
			}
			else{
				saveAs("tiff", savename);
			}
			if (addScale == true){
				addScalebar(width, height, pixelWidth, prvType);
			}
			run("Close All");
		}
		count++;
		print("Saved "+count+" of "+list.length);
	}
	else{
		print("--> Skipping "+ list[i] + ", file type incorrect.");
	}
}

//Reset brightness and autobrighten each channel
function brighten(channels){
	for (j=0; j<channels; j++) {
		Stack.setChannel(j+1);
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.60");
	}
}

//Calculate add add a scalebar before saving as a flattened RGB image
function addScalebar(width, height, pixelWidth, prvType){
	abwidth = width*pixelWidth;
	division = floor(abwidth/4);
	scaleWidth = division;
	if(division > 50){
		rem = division%50;
		scaleWidth = division-rem;
		}
	if(division < 50 && division >10){
		rem = division%5;
		scaleWidth = division-rem;
		}
	scaleHeight = floor(height/40);
	print("- RGB Scalebar : Height (pixels) " + scaleHeight + ", Width (um) " + scaleWidth);
	run("Scale Bar...", "width="+scaleWidth+" height="+scaleHeight+" font=10 color=White background=None location=[Lower Right] hide overlay");
	run("Flatten");
	saveAs(prvType, savename+"_"+scaleWidth+"um");
}

//Notify user that script is finished
print("Finished resaving "+count+" Images");
print(" ");
