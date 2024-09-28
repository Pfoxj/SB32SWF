// simple text outputs

package
{
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextField;
	
	public class TextOutput extends TextField
	{
		private var format:TextFormat=new TextFormat();
		
		public function TextOutput(text:String)
		{
			// setup formatting and position
			format.size=20;
			
			// TODO: check web safety
			format.font="Arial,sans-serif";
			format.color=0x000000;
			autoSize=TextFieldAutoSize.LEFT;
			defaultTextFormat=format;
			selectable=false;
			this.text=text;
		}
		
		// change text
		public function setText(text:String):void
		{
			this.text=text;
		}
		
		// change color
		public function setColor(color:uint):void
		{
			format.color=color;
			defaultTextFormat=format;
			setTextFormat(format);
		}
	}
}
