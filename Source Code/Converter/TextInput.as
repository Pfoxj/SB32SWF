// simple text input field with label

package
{
	import flash.events.*;
	import flash.display.*;
	import flash.text.*;
	import flash.ui.*;
	
	public class TextInput extends Sprite
	{
		public var input:TextOutput;
		public function TextInput(labelText:String,defaultText:String,restrict:String=null)
		{	
			// make label
			var label:TextOutput=new TextOutput(labelText);
			addChild(label);
			
			// draw outline
			var outline:Sprite=new Sprite();
			outline.graphics.beginFill(0xFFFFFF);
			outline.graphics.lineStyle(2,0xAAAAAA);
			outline.graphics.drawRoundRect(0,0,100,25,10);
			outline.graphics.endFill();
			outline.x=label.width+5;
			addChild(outline);
			
			// setup input field
			input=new TextOutput(defaultText);
			input.type=TextFieldType.INPUT;
			input.restrict=restrict;
			input.width=94;
			input.maxChars=7;
			input.selectable=true;
			outline.addChild(input);
			
			// add listeners
			outline.addEventListener(MouseEvent.CLICK,selectInput);
			outline.addEventListener(MouseEvent.ROLL_OVER,showTextCursor);
			outline.addEventListener(MouseEvent.ROLL_OUT,hideTextCursor);
		}
		
		// get and set the text in the input field
		public function getText():String
		{
			return input.text;
		}
		public function setText(text:String):void
		{
			input.text=text;
		}
		
		// place the cursor at the end of the input field
		private function selectInput(event:MouseEvent):void
		{
			stage.focus=input;
			input.setSelection(input.text.length,input.text.length);
		}
		
		// switch to text cursor when mouse over
		private function showTextCursor(event:MouseEvent):void
		{
			Mouse.cursor=MouseCursor.IBEAM;
		}
		
		// switch back to normal cursor
		private function hideTextCursor(event:MouseEvent):void
		{
			Mouse.cursor=MouseCursor.AUTO;
		}
	}
}
