package
{
	
	import sentinel.testing.TestGame;
	import states.Menu;
	
	
	public class MazeGame extends TestGame
	{
		
		public override function construct():void
		{
			super.construct();
			
			loadState(new Menu());
		}
		
	}
	
}