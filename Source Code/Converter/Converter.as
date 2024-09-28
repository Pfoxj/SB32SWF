// this is the main class of the converter

package
{
	import flash.utils.*;
	import flash.events.*;
	import flash.net.*;
	import flash.display.*;
	
	[SWF(width="500",height="275")]
	public class Converter extends Sprite
	{
		// settings byte offsets
		private static const SETTING_FULLSCREEN:int=0;
		private static const SETTING_GREEN_FLAG_BAR:int=1;
		private static const SETTING_TURBO_MODE:int=2;
		private static const SETTING_AUTO_START:int=3;
		private static const SETTING_EDIT_MODE:int=4;
		private static const SETTING_HIDE_CURSOR:int=5;
		
		// settings string characters
		private static const CHAR_0:int=48;
		private static const CHAR_1:int=49;
		
		// SWF projector parts
		[Embed(source="PartHeader.bin",mimeType="application/octet-stream")]
		private static const PartHeader:Class;
		[Embed(source="PartChunkBefore.bin",mimeType="application/octet-stream")]
		private static const PartChunkBefore:Class;
		[Embed(source="PartSB2Header.bin",mimeType="application/octet-stream")]
		private static const PartSB2Header:Class;
		[Embed(source="PartChunkBetween.bin",mimeType="application/octet-stream")]
		private static const PartChunkBetween:Class;
		[Embed(source="PartChunkAfter.bin",mimeType="application/octet-stream")]
		private static const PartChunkAfter:Class;
		[Embed(source="Order.bin",mimeType="application/octet-stream")]
		private static const Order:Class;
		
		// for saving and loading
		private var uploadFile:FileReference=new FileReference();
		private var downloadFile:FileReference=new FileReference();
		
		// UI elements
		private var openButton:Button;
		private var openText:TextOutput;
		
		private var fullScreenBox:CheckBox;
		private var greenFlagBarBox:CheckBox;
		private var turboModeBox:CheckBox;
		private var autoStartBox:CheckBox;
		private var editModeBox:CheckBox;
		private var hideCursorBox:CheckBox;
		
		private var widthField:TextInput;
		private var heightField:TextInput;
		
		private var convertButton:Button;
		private var convertText:TextOutput;
		
		private var extensionWarning:Sprite;
		private var dimensionsWarning:Sprite;
		
		public function Converter() 
		{
			// setup UI elements
			openButton=new Button("Open Scratch File",uploadBrowse);
			openButton.x=5;
			openButton.y=5;
			addChild(openButton);
			
			openText=new TextOutput("");
			openText.x=openButton.x+openButton.width+5;
			openText.y=openButton.y;
			openText.setColor(0xAAAAAA);
			addChild(openText);
			
			fullScreenBox=new CheckBox("Full Screen");
			fullScreenBox.x=5;
			fullScreenBox.y=openButton.y+openButton.height+5;
			addChild(fullScreenBox);
			
			greenFlagBarBox=new CheckBox("Show Green Flag Bar");
			greenFlagBarBox.x=5;
			greenFlagBarBox.y=fullScreenBox.y+fullScreenBox.height+2;
			addChild(greenFlagBarBox);
			
			turboModeBox=new CheckBox("Start in Turbo Mode");
			turboModeBox.x=5;
			turboModeBox.y=greenFlagBarBox.y+greenFlagBarBox.height+2;
			addChild(turboModeBox);
			
			autoStartBox=new CheckBox("Automatically Start");
			autoStartBox.x=5;
			autoStartBox.y=turboModeBox.y+turboModeBox.height+2;
			addChild(autoStartBox);
			
			editModeBox=new CheckBox("Show as Editor");
			editModeBox.x=5;
			editModeBox.y=autoStartBox.y+autoStartBox.height+2;
			addChild(editModeBox);
			
			hideCursorBox=new CheckBox("Hide Mouse Cursor");
			hideCursorBox.x=5;
			hideCursorBox.y=editModeBox.y+editModeBox.height+2;
			addChild(hideCursorBox);
			
			widthField=new TextInput("Width:","480");
			widthField.x=5;
			widthField.y=hideCursorBox.y+hideCursorBox.height+2;
			addChild(widthField);
			
			heightField=new TextInput("Height:","360");
			heightField.x=widthField.x+widthField.width+10;
			heightField.y=hideCursorBox.y+hideCursorBox.height+2;
			addChild(heightField);
			
			convertButton=new Button("Convert to SWF",convert);
			convertButton.disable();
			convertButton.x=5;
			convertButton.y=widthField.y+widthField.height+5;
			addChild(convertButton);
			
			convertText=new TextOutput("");
			convertText.x=convertButton.x+convertButton.width+10;
			convertText.setColor(0xAAAAAA);
			convertText.y=convertButton.y;
			addChild(convertText);
			
			// TODO: make an error dialog class I guess
			extensionWarning=new Sprite();
			var extensionWarningText:TextOutput=new TextOutput("Warning!\n\nYou did not save the file with a SWF extension.\nThis will cause most programs to fail to open it.\nWhen you save the file, add \".swf\" to the name.\n(For example, rather than \"Game\", type in \"Game.swf\")\n\n\n\n\n\n(click to close)");
			extensionWarning.graphics.beginFill(0xFFFFFF,0.9);
			extensionWarning.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			extensionWarning.graphics.endFill();
			extensionWarning.addChild(extensionWarningText);
			extensionWarning.mouseChildren=false;
			extensionWarning.buttonMode=true;
			extensionWarning.addEventListener(MouseEvent.CLICK,removeExtensionWarning);
			function removeExtensionWarning(event:MouseEvent):void
			{
				removeChild(extensionWarning);
			}
			
			dimensionsWarning=new Sprite();
			var dimensionsWarningText:TextOutput=new TextOutput("Error!\n\nYour width or height values are invalid.\nThey must both be integers between 50 and 2000.\nPlease fix this and then try converting again.\n\n\n\n\n\n\n(click to close)");
			dimensionsWarning.graphics.beginFill(0xFFFFFF,0.9);
			dimensionsWarning.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			dimensionsWarning.graphics.endFill();
			dimensionsWarning.addChild(dimensionsWarningText);
			dimensionsWarning.mouseChildren=false;
			dimensionsWarning.buttonMode=true;
			dimensionsWarning.addEventListener(MouseEvent.CLICK,removeDimensionsWarning);
			function removeDimensionsWarning(event:MouseEvent):void
			{
				removeChild(dimensionsWarning);
			}
			
			// file upload and save listeners
			uploadFile.addEventListener(Event.SELECT,uploadLoad);
			uploadFile.addEventListener(Event.CANCEL,uploadCancel);
			uploadFile.addEventListener(IOErrorEvent.IO_ERROR,uploadError);
			uploadFile.addEventListener(Event.COMPLETE,uploadComplete);
			
			downloadFile.addEventListener(Event.COMPLETE,downloadComplete);
			downloadFile.addEventListener(Event.CANCEL,downloadCancel);
		}
		
		// open the Scratch project
		public function uploadBrowse():void
		{
			// disable buttons
			openButton.disable();
			convertButton.disable();
			
			// browse for file
			uploadFile.browse();
		}
		
		// error with SB2 upload
		private function uploadError(event:Event):void
		{
			openText.setText("Upload Error");
			uploadCancel();
		}
		
		// open file dialog cancelled
		private function uploadCancel(event:Event=null):void
		{
			openButton.enable();
			
			// only enable convert button if SB2 previously chosen
			if(uploadFile.data)
			{
				convertButton.enable();
			}
		}
		
		// load Scratch project
		private function uploadLoad(event:Event):void
		{
			openText.setText("Uploading...");
			uploadFile.load();
		}
		
		// finished loading Scratch project
		private function uploadComplete(event:Event):void
		{
			// show file name next to open button
			openText.setText(uploadFile.name);
			
			// enable buttons
			openButton.enable();
			convertButton.enable();
		}
		
		// convert to SWF
		private function convert():void
		{
			// disable buttons
			openButton.disable();
			convertButton.disable();
			
			// built-in projector parts
			var partHeader:ByteArray=new PartHeader() as ByteArray;
			var partChunkBefore:ByteArray=new PartChunkBefore() as ByteArray;
			var partSB2Header:ByteArray=new PartSB2Header() as ByteArray;
			var partChunkBetween:ByteArray=new PartChunkBetween() as ByteArray;
			var partChunkAfter:ByteArray=new PartChunkAfter() as ByteArray;
			
			// generate width and height RECT
			var widthParsed:int=parseInt(widthField.getText(),10);
			var heightParsed:int=parseInt(heightField.getText(),10);
			if(!(widthParsed>=50&&widthParsed<=2000)||!(heightParsed>=50&&heightParsed<=2000))
			{
				addChild(dimensionsWarning);
				downloadCancel();
				return;
			}
			widthField.setText(""+widthParsed);
			heightField.setText(""+heightParsed);
			
			// multiply by 20 for pixels to twips conversion
			var partDimensions:ByteArray=toRECT(widthParsed*20,heightParsed*20);
			
			// SWF total filesize
			var partSWFSize:ByteArray=toUI32(partHeader.length+4+partDimensions.length+partChunkBefore.length+4+partSB2Header.length+uploadFile.size+partChunkBetween.length+21+partChunkAfter.length);
			
			// SB2 filesize
			var partSB2Size:ByteArray=toUI32(6+uploadFile.size);
			
			// SB2 file
			var partSB2:ByteArray=uploadFile.data;
			
			// force some settings based on other settings
			var greenFlagBarOn:Boolean=greenFlagBarBox.on||editModeBox.on;
			var hideCursorOn:Boolean=hideCursorBox.on&&!editModeBox.on;
			
			// make settings part
			// TODO: make variables for things like settings file length
			var partSettings:ByteArray=new ByteArray();
			for(var padding:int=0;padding<21;padding++)
			{
				partSettings[padding]=CHAR_0;
			}
			partSettings[SETTING_FULLSCREEN]=fullScreenBox.on?CHAR_1:CHAR_0;
			partSettings[SETTING_GREEN_FLAG_BAR]=greenFlagBarOn?CHAR_1:CHAR_0;
			partSettings[SETTING_TURBO_MODE]=turboModeBox.on?CHAR_1:CHAR_0;
			partSettings[SETTING_AUTO_START]=autoStartBox.on?CHAR_1:CHAR_0;
			partSettings[SETTING_EDIT_MODE]=editModeBox.on?CHAR_1:CHAR_0;
			partSettings[SETTING_HIDE_CURSOR]=hideCursorOn?CHAR_1:CHAR_0;
			
			// combine parts
			var swf:ByteArray=new ByteArray();
			swf.writeBytes(partHeader);
			swf.writeBytes(partSWFSize);
			swf.writeBytes(partDimensions);
			swf.writeBytes(partChunkBefore);
			
			// order of converter-added binary files can change
			// this happens at random when building the projector
			// it is based on mxmlc's optimizations and cannot be controlled
			// the build script detects which is first
			// this information is written to Order.bin
			var sb2BinaryFirst:Boolean=(new Order() as ByteArray)[0]==CHAR_1;
			if(sb2BinaryFirst)
			{
				swf.writeBytes(partSB2Size);
				swf.writeBytes(partSB2Header);
				swf.writeBytes(partSB2);
				swf.writeBytes(partChunkBetween);
				swf.writeBytes(partSettings);
			}
			else
			{
				swf.writeBytes(partSettings);
				swf.writeBytes(partChunkBetween);
				swf.writeBytes(partSB2Size);
				swf.writeBytes(partSB2Header);
				swf.writeBytes(partSB2);
			}
			swf.writeBytes(partChunkAfter);
			
			// download the SWF file
			// TODO: do something about the file extension
			// setting the default name with a SWF extension will fail on Chrome
			convertText.setText("Saving...");
			downloadFile.save(swf);
		}
		
		// save file dialog cancelled
		private function downloadCancel(event:Event=null):void
		{
			convertText.setText("");
			openButton.enable();
			convertButton.enable();
		}
		
		// finished saving the SWF
		private function downloadComplete(event:Event):void
		{
			// show file name next to convert button
			convertText.setText(downloadFile.name);
			
			if(downloadFile.name.substr(downloadFile.name.length-4,downloadFile.name.length).toLowerCase()==".swf")
			{
			}
			else
			{
				addChild(extensionWarning);
			}
			
			// enable buttons
			convertButton.enable();
			openButton.enable();
		}
		
		// convert an int to a 4 byte unsigned integer
		private function toUI32(number:int):ByteArray
		{
			var result:ByteArray=new ByteArray();
			var i:int=0;
			while(i<4)
			{
				result[i]=number%256;
				number=(number-result[i])/256;
				i++;
			}
			return result;
		}
		
		// TODO: using Strings of 1's and 0's is really, really stupid
		// TODO: redo this some day
		
		// generate the width and height RECT
		private function toRECT(w:int,h:int):ByteArray
		{
			var length:int=Math.max(toBits(w).length,toBits(h).length)+1;
			var a:String=pad(toBits(length),5);
			var b:String="0";
			var c:String="0"+toBits(w);
			var d:String="0";
			var e:String="0"+toBits(h);
			function pad(string:String,length:int):String
			{
				while(string.length<length)
				{
					string="0"+string;
				}
				return string;
			}
			var bits:String=a+pad(b,length)+pad(c,length)+pad(d,length)+pad(e,length);
			var i:int=0;
			while(i<=bits.length%8)
			{
				i++;
				bits=bits+"0";
			}
			return(toBytes(bits));
		}
		
		// convert an int to a String of 1's and 0's
		private function toBits(number:int):String
		{
			var result:String="";
			while(number!=0)
			{
				result=(number%2).toString(10)+result;
				number=(number-number%2)/2;
			}
			return result;
		}
		
		// convert a String of 1's and 0's to the corresponding bytes
		private function toBytes(binary:String):ByteArray
		{
			var result:ByteArray=new ByteArray();
			var byte:int=0;
			var index:int=0;
			var number:int;
			var place:int;
			var bit:int;
			while(byte<binary.length/8)
			{
				number=0;
				place=128;
				bit=0;
				while(bit<8)
				{
					number=number+(binary.charAt(index)=="1"?place:0);
					place=place/2;
					bit++;
					index++;
				}
				result[byte]=number;
				byte++;
			}
			return result;
		}
	}
}
