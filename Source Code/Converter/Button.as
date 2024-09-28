// a button

package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class Button extends Sprite
	{
		private var text:TextOutput;
		private var whenClicked:*;
		private var w:int;
		
		public function Button(name:String,whenClicked:*)
		{
			text=new TextOutput(name);
			text.x=5;
			this.whenClicked=whenClicked;
			w=text.x+text.width+10;
			mouseChildren=false;
			addChild(text);
			enable();
			up(null);
		}
		
		// enable the button
		public function enable():void
		{
			text.setColor(0x000000);
			useHandCursor=true;
			buttonMode=true;
			addEventListener(MouseEvent.CLICK,click);
			addEventListener(MouseEvent.ROLL_OVER,over);
			addEventListener(MouseEvent.ROLL_OUT,up);
		}
		
		// disable the button
		public function disable():void
		{
			text.setColor(0xAAAAAA);
			up(null);
			useHandCursor=false;
			buttonMode=false;
			removeEventListener(MouseEvent.CLICK,click);
			removeEventListener(MouseEvent.ROLL_OVER,over);
			removeEventListener(MouseEvent.ROLL_OUT,up);
		}
		
		// mouse over
		private function over(event:MouseEvent):void
		{
			graphics.clear();
			graphics.lineStyle(2,0xAAAAAA);
			graphics.beginFill(0xBBBBBB);
			graphics.drawRoundRect(0,0,w,25,10);
			graphics.endFill();
		}
		
		// mouse off
		private function up(event:MouseEvent):void
		{
			graphics.clear();
			graphics.lineStyle(2,0xAAAAAA);
			graphics.beginFill(0xDDDDDD);
			graphics.drawRoundRect(0,0,w,25,10);
			graphics.endFill();
		}
		
		// clicked
		private function click(event:MouseEvent):void
		{
			whenClicked();
		}
	}
}
