package dungeons;

import nme.display.BitmapData;
import dungeons.components.Renderable;
import dungeons.components.Renderable;
import com.haxepunk.graphics.Image;
import nme.display.BitmapData;
import com.haxepunk.graphics.TiledImage;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.Graphic;
import com.haxepunk.graphics.Tilemap;
import com.haxepunk.HXP;
import com.haxepunk.World;

import haxe.Json;

import nme.display.Bitmap;
import nme.ObjectHash;
import nme.display.DisplayObjectContainer;
import nme.events.KeyboardEvent;
import nme.ui.Keyboard;
import nme.display.Shape;
import nme.Assets;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.events.Event;
import nme.display.BitmapData;
import nme.display.StageScaleMode;
import nme.display.Sprite;
import nme.text.TextFormat;
import nme.text.TextField;
import nme.Lib;

import ash.core.Engine;
import ash.core.Entity;

import dungeons.components.Description;
import dungeons.components.MonsterAI;
import dungeons.components.Obstacle;
import dungeons.components.FOV;
import dungeons.components.CameraFocus;
import dungeons.components.Actor;
import dungeons.components.PlayerControls;
import dungeons.components.Position;
import dungeons.components.LightOccluder;
import dungeons.components.DoorRenderable;
import dungeons.components.Door;
import dungeons.components.Fighter;

import dungeons.systems.MessageLogSystem;
import dungeons.systems.FightSystem;
import dungeons.systems.MonsterAISystem;
import dungeons.systems.SystemPriorities;
import dungeons.systems.MoveSystem;
import dungeons.systems.ActorSystem;
import dungeons.systems.CameraSystem;
import dungeons.systems.FOVSystem;
import dungeons.systems.PlayerControlSystem;
import dungeons.systems.RenderSystem;
import dungeons.systems.ObstacleSystem;
import dungeons.systems.DoorSystem;

import dungeons.Dungeon;
import dungeons.ShadowCaster;
import dungeons.Eight2Empire;

using dungeons.ArrayUtil;

class GameWorld extends World
{
    private var engine:Engine;
    private var renderSystem:RenderSystem;

    public function new()
    {
        super();
    }

    override public function begin()
    {
        engine = new Engine();

        var dungeon:Dungeon = new Dungeon(50, 50, 25, {x: 5, y: 5}, {x: 20, y: 20});
        dungeon.generate();

        var levelBmp:BitmapData = Assets.getBitmapData("eight2empire/level assets.png");
        var charBmp:BitmapData = Assets.getBitmapData("oryx_lofi/lofi_char.png");

        var levelGraphic:Graphic = renderDungeon(dungeon, levelBmp);
        var level:Entity = new Entity();
        level.add(new Renderable(levelGraphic, RenderLayers.DUNGEON));
        level.add(new Position());
        engine.addEntity(level);

        var lightOccluder:LightOccluder = new LightOccluder();
        var obstacle:Obstacle = new Obstacle();

        var startRoom:Room = dungeon.rooms.randomChoice();

        var hero:Entity = new Entity();
        hero.name = "player";
        hero.add(new Renderable(createTileImage(charBmp, 0, 0), RenderLayers.CHARACTER));
        hero.add(new PlayerControls());
        hero.add(new Actor(100));
        hero.add(new Position(startRoom.x + Std.int(startRoom.grid.width / 2), startRoom.y + Std.int(startRoom.grid.height / 2)));
        hero.add(new CameraFocus());
        hero.add(new FOV(10));
        hero.add(new Fighter(10, 3, 2));
        hero.add(obstacle);
        engine.addEntity(hero);


        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y))
                {
                    case Wall:
                        var entity:Entity = new Entity();
                        entity.add(new Position(x, y));
                        entity.add(obstacle);
                        entity.add(lightOccluder);
                        engine.addEntity(entity);
                    case Door(open):
                        var door:Entity = new Entity();
                        door.add(new Position(x, y));
                        door.add(new dungeons.components.Door(open));
                        door.add(new DoorRenderable(createTileImage(levelBmp, 2, 31), createTileImage(levelBmp, 2, 30)), Renderable);
                        engine.addEntity(door);
                    default:
                        continue;
                }
            }
        }

        var monsterAI = new MonsterAI();
        var monsterDefs:Array<MonsterDefinition> = cast Json.parse(Assets.getText("monsters.json"));
        for (room in dungeon.rooms)
        {
            if (room != startRoom)
            {
                var monsterDef:MonsterDefinition = monsterDefs.randomChoice();
                var monster:Entity = new Entity();
                monster.add(new Description(monsterDef.name));
                monster.add(new Renderable(createTileImage(charBmp, monsterDef.tileCol, monsterDef.tileRow), RenderLayers.CHARACTER));
                monster.add(new Position(room.x + Std.int(room.grid.width / 2), room.y + Std.int(room.grid.height / 2)));
                monster.add(new Actor(100));
                monster.add(new Fighter(monsterDef.hp, monsterDef.power, monsterDef.defense));
                monster.add(monsterAI);
                monster.add(obstacle);
                engine.addEntity(monster);
            }
        }
        /*




                for (room in dungeon.rooms)
                {
                    var feature:RoomFeature = Type.allEnums(RoomFeature).randomChoice();
                    switch (feature)
                    {
                        case Library:
                            var y:Int = room.y + 1;
                            for (x in room.x + 1...room.x + room.grid.width - 1)
                            {
                                if (Math.random() < 0.25)
                                    continue;

                                if (x == room.x + 1 && dungeon.grid.get(x - 1, y) != Tile.Wall)
                                    continue;

                                if (x == room.x + room.grid.width - 2 && dungeon.grid.get(x + 1, y) != Tile.Wall)
                                    continue;

                                if (dungeon.grid.get(x, y - 1) != Tile.Wall)
                                    continue;

                                var shelf:Entity = new Entity();
                                shelf.add(new Position(x, y));
                                shelf.add(obstacle);
                                shelf.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 14 + Std.random(6), 22)));
                                engine.addEntity(shelf);
                            }
                        case Fountain:

                            var fountain:Entity = new Entity();
                            fountain.add(new Position(room.x + Std.int(room.grid.width / 2), Std.int(room.y + room.grid.height / 2)));
                            fountain.add(obstacle);
                            fountain.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 15, 28)));
                            engine.addEntity(fountain);

                        default:
                    }
                }
        */

        // These systems don't do anything on ticks, instead they react on signals
        engine.addSystem(new MonsterAISystem(), SystemPriorities.NONE);
        engine.addSystem(new ObstacleSystem(dungeon.width, dungeon.height), SystemPriorities.NONE);
        engine.addSystem(new FOVSystem(dungeon.width, dungeon.height), SystemPriorities.NONE);
        engine.addSystem(new MoveSystem(), SystemPriorities.NONE);
        engine.addSystem(new CameraSystem(), SystemPriorities.NONE);
        engine.addSystem(new DoorSystem(), SystemPriorities.NONE);
        engine.addSystem(new FightSystem(), SystemPriorities.NONE);

        // Input system runs first
        engine.addSystem(new PlayerControlSystem(), SystemPriorities.INPUT);

        // Then actors are processed, here other systems can run because of action processing
        engine.addSystem(new ActorSystem(), SystemPriorities.ACTOR);

        // rendering comes last.
        engine.addSystem(new RenderSystem(this), SystemPriorities.RENDER);
        engine.addSystem(new MessageLogSystem(createMessageField(), 6), SystemPriorities.RENDER);
    }

    private static function createTileImage(bmp:BitmapData, col:Int, row:Int):Image
    {
        return new Image(bmp, new Rectangle(col * Constants.TILE_SIZE, row * Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE));
    }

    private static function renderDungeon(dungeon:Dungeon, tileset:BitmapData):Graphic
    {
        var tilemapWidth:Int = dungeon.width * Constants.TILE_SIZE;
        var tilemapHeight:Int = dungeon.height * Constants.TILE_SIZE;

        var tilesetCols:Int = Math.floor(tileset.width / Constants.TILE_SIZE);
        var floorTilemap:Tilemap = new Tilemap(tileset, tilemapWidth, tilemapHeight, Constants.TILE_SIZE, Constants.TILE_SIZE);
        var wallTilemap:Tilemap = new Tilemap(tileset, tilemapWidth, tilemapHeight, Constants.TILE_SIZE, Constants.TILE_SIZE);

        var floorCol:Int = 4;
        var floorRow:Int = 0;
        var floorTileIndex:Int = tilesetCols * floorRow + floorCol;
        var wallRow:Int = 2;

        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y))
                {
                    case Floor, Door(_):
                        floorTilemap.setTile(x, y, floorTileIndex);

                    case Wall:
                        floorTilemap.setTile(x, y, floorTileIndex);

                        var wallCol:Int = Eight2Empire.getTileNumber(dungeon.getWallTransition(x, y));
                        wallTilemap.setTile(x, y, tilesetCols * wallRow + wallCol);
                    default:
                        continue;
                }
            }
        }

        return new Graphiclist([floorTilemap, wallTilemap]);
    }

    /**
     * Create and add a textfield for displaying in-game messages
     **/
    private function createMessageField():TextField
    {
        var messageField:TextField = new TextField();
        messageField.width = HXP.width;
        messageField.mouseEnabled = false;
        messageField.selectable = false;
        messageField.embedFonts = true;
        messageField.defaultTextFormat = new TextFormat(Assets.getFont("eight2empire/eight2empire.ttf").fontName, 16, 0xFFFFFF);
        HXP.engine.addChild(messageField);
        return messageField;
    }

    /**
     * Update game entities and systems
     **/
    override public function update()
    {
        super.update();
        engine.update(HXP.elapsed);
    }
}


enum RoomFeature
{
    None;
    Library;
    Fountain;
    Light;
}

private typedef MonsterDefinition =
{
    var name:String;
    var tileRow:Int;
    var tileCol:Int;
    var hp:Int;
    var power:Int;
    var defense:Int;
}