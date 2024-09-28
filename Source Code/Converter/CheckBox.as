// a checkbox

package
{
	import flash.display.*;
	import flash.events.*;
	public class CheckBox extends Sprite
	{
		private var label:TextOutput;
		private var box:Shape;
		
		public var on:Boolean=true;
		
		public function CheckBox(labelText:String)
		{	
			useHandCursor=true;
			buttonMode=true;
			mouseChildren=false;
			
			addEventListener(MouseEvent.CLICK,toggle);
			
			box=new Shape();
			box.x=5;
			box.y=5;
			addChild(box);
			toggle();
			
			label=new TextOutput(labelText);
			label.x=box.x+box.width+5;
			addChild(label);
		}
		
		// checkbox clicked
		public function toggle(event:MouseEvent=null):void
		{
			box.graphics.clear();
			box.graphics.lineStyle(2,0xAAAAAA);
			box.graphics.beginFill(0xFFFFFF);
			box.graphics.drawRoundRect(0,0,15,15,5);
			box.graphics.endFill();
			
			on=!on;
			if(on)
			{
				box.graphics.lineStyle(4,0x000000);
				box.graphics.moveTo(2,6);
				box.graphics.lineTo(5,13);
				box.graphics.lineTo(13,2);
				on=true;
			}
		}
	}
}
