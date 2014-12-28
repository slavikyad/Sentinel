package sentinel.gameplay.world
{
	
	import flash.utils.getDefinitionByName;
	import sentinel.framework.Data;
	import sentinel.framework.graphics.IGraphics;
	import sentinel.framework.Thing;
	import sentinel.gameplay.IPositionProvider;
	import sentinel.gameplay.physics.Body;
	import sentinel.gameplay.physics.Engine;
	import sentinel.gameplay.physics.Vector2D;
	import sentinel.gameplay.ui.UI;
	import starling.display.DisplayObject;
	
	
	/**
	 * A Being is an object that lives in a World. It can define graphics and a physics body. It
	 * should be used as the base class for all of your gameplay objects within a World like trees,
	 * enemies, loot, projectiles, the main hero, etc.
	 * @author Marty Wallace.
	 */
	public class Being extends Thing implements IPositionProvider
	{
		
		/**
		 * Attempts to create a new Being from save data obtained via <code>Being.save()</code>.
		 * @param type The type of object to try and create, as a fully qualified class name.
		 * @param data The save data.
		 */
		public static function create(type:String, save:Data):Being
		{
			var className:Class = null;
			
			try
			{
				// Attempt to obtain the class definition from the 'type' string value.
				className = getDefinitionByName(type) as Class;
			}
			catch (error:ReferenceError)
			{
				throw new Error('Type "' + type + '" could not be loaded. You may need to manually reference this type in your project.');
				return null;
			}
			
			var being:Being = new className() as Being;
			being.load(save);
			
			return being;
		}
		
		
		private var _graphics:IGraphics;
		private var _body:Body;
		private var _position:Vector2D;
		private var _rotation:Number = 0;
		
		
		/**
		 * Constructor.
		 */
		public function Being()
		{
			_position = new Vector2D();
		}
		
		
		/**
		 * Deconstruct this Being. Also deconstructs its graphics and physics body. If this Being
		 * belongs to a World, it will remove itself from it.
		 */
		public override function deconstruct():void
		{
			if (_graphics !== null) _graphics.deconstruct();
			if (_body !== null) _body.deconstruct();
			
			super.deconstruct();
		}
		
		
		protected override function update():void
		{
			alignGraphics();
			
			super.update();
		}
		
		
		/**
		 * Position and rotate the graphics owned by this Being to mimic its physics body.
		 * This method does nothing unless this Being owns both graphics and a physics body.
		 */
		public function alignGraphics():void
		{
			if (_graphics !== null)
			{
				if (_body !== null)
				{
					_graphics.x = _body.position.x;
					_graphics.y = _body.position.y;
					_graphics.rotation = _body.rotation;
				}
				else
				{
					_graphics.x = _position.x;
					_graphics.y = _position.y;
					_graphics.rotation = _rotation;
				}
			}
		}
		
		
		/**
		 * Position and rotate the physics body owned by this Being to mimic its graphics.
		 * This method does nothing unless this Being owns both a physics body and graphics.
		 */
		public function alignBody():void
		{
			if (_body !== null)
			{
				if (_graphics !== null)
				{
					_body.moveTo(_graphics.x, _graphics.y);
					_body.rotation = _graphics.rotation;
				}
				else
				{
					_body.moveTo(_position.x, _position.y);
					_body.rotation = _rotation;
				}
			}
		}
		
		
		/**
		 * Utility to method for setting the x and y values at the same time.
		 * @param x The new x coordinate.
		 * @param y The new y coordinate.
		 */
		public function moveTo(x:Number, y:Number):void
		{
			_position.x = x;
			_position.y = y;
			
			if (_body !== null)
			{
				_body.moveTo(x, y);
			}
			
			if (_graphics !== null)
			{
				_graphics.x = x;
				_graphics.y = y;
			}
		}
		
		
		/**
		 * Saves a simple representation of this Being, useful for working with
		 * <code>Being.create()</code>.
		 */
		public override function save():Data
		{
			return super.save().merge({
				x: Number(x.toFixed(2)),
				y: Number(y.toFixed(2)),
				rotation: rotation
			});
		}
		
		
		/**
		 * Applies properties stored in a simple object to this Being.
		 * @param data The data to apply.
		 */
		public override function load(data:Data):void
		{
			x = data.prop('x');
			y = data.prop('y');
			rotation = data.prop('rotation', 0);
		}
		
		
		/**
		 * Removes this Being from its parent World.
		 * @param destroy Whether or not to also <code>deconstruct()</code> this Being.
		 */
		public override function removeFromParent(destroy:Boolean = false):void
		{
			if (world !== null)
			{
				world.remove(this, destroy);
				super.removeFromParent(destroy);
			}
		}
		
		
		protected final override function added(world:Thing):void
		{
			if (world is World)
			{
				_graphics = defineGraphics();
				
				if (_graphics !== null)
				{
					// Add the graphics to the World's graphics container.
					(world as World).__content.addChild(_graphics as DisplayObject);
					
					if (!_graphics.atZero)
					{
						// If the position of the graphics has been modified, use those values for
						// the final position.
						moveTo(_graphics.x, _graphics.y);
						rotation = _graphics.rotation;
					}
					else
					{
						alignGraphics();
					}
				}
				
				if ((world as World).engine !== null)
				{
					// Attempt to define a body for this Being.
					_body = defineBody((world as World).engine);
					
					if (_body !== null)
					{
						if (!_body.atZero)
						{
							// If the position of the body has been modified, use those values for the
							// final position. This overrides the position of the graphics.
							moveTo(_body.position.x, _body.position.y);
							rotation = _body.rotation;
						}
						else
						{
							alignBody();
						}
					}
				}
			}
			else
			{
				throw new Error("Instances of Being can only be added to a World.");
			}
		}
		
		
		protected final override function removed(world:Thing):void
		{
			if (world is World)
			{
				if (_graphics !== null) _graphics.deconstruct();
				if (_body !== null) _body.deconstruct();
			}
			else
			{
				throw new Error("Instances of Being can only be removed from a World.");
			}
		}
		
		
		/**
		 * Defines graphics to be used by this Being. Graphics are defined when this Being is added
		 * to a World.
		 */
		protected function defineGraphics():IGraphics
		{
			return null;
		}
		
		
		/**
		 * Defines a physics body to be used by this Being. The body is defined when this Being is
		 * added to a World.
		 * @param engine A reference to the physics engine.
		 */
		protected function defineBody(engine:Engine):Body
		{
			return null;
		}
		
		
		/**
		 * The parent World containing this Being.
		 */
		public function get world():World { return parent as World; }
		
		/**
		 * The Map loaded by the parent World containing this Being.
		 */
		public function get map():Map{ return world.map; }
		
		/**
		 * The graphics representing this Being.
		 */
		public function get graphics():IGraphics { return _graphics; }
		
		/**
		 * The physics body used by this Being.
		 */
		public function get body():Body { return _body; }
		
		/**
		 * Returns the position of this Being. Modifying the <code>x</code> or <code>y</code> values
		 * of the result will not affect this Being, use <code>moveTo()</code> or modify the
		 * <code>x</code> and <code>y</code> values of this Being directly instead.
		 */
		public function get position():Vector2D
		{
			if (_graphics !== null)
			{
				_position.x = _graphics.x;
				_position.y = _graphics.y;
			}
			
			if (_body !== null)
			{
				_position.x = _body.position.x;
				_position.y = _body.position.y;
			}
			
			return _position;
		}
		
		/**
		 * Get or set the x position of this Being.
		 * This is an alias for <code>position.x</code> and <code>moveTo(value, y)</code>.
		 */
		public function get x():Number { return position.x; }
		public function set x(value:Number):void { moveTo(value, position.y); }
		
		/**
		 * Get or set the y position of this Being.
		 * This is an alias for <code>position.y</code> and <code>moveTo(x, value)</code>.
		 */
		public function get y():Number { return position.y; }
		public function set y(value:Number):void { moveTo(position.x, value); }
		
		/**
		 * Get or set the rotation of this Being.
		 */
		public function get rotation():Number
		{
			if (_graphics !== null) _rotation = _graphics.rotation;
			if (_body !== null) _rotation = _body.rotation;
			
			return _rotation;
		}
		
		public function set rotation(value:Number):void
		{
			_rotation = value;
			
			if (_body !== null) _body.rotation = value;
			if (_graphics !== null) _graphics.rotation = value;
		}
		
		/**
		 * Returns the active UI, if this Being is a descendant of <code>GameplayState</code>.
		 */
		protected function get ui():UI { return world !== null ? world.ui : null; }
		
	}
	
}