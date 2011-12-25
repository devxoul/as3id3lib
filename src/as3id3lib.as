package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import kr.xoul.as3id3lib.ID3;
	import kr.xoul.as3id3lib.Tag;
	
	public class as3id3lib extends Sprite
	{
		public static var file : File = new File().resolvePath( "/Users/xoul/Flash/Libraries/as3id3lib/examples/iu.mp3" );
		
		public function as3id3lib()
		{
			var id3 : ID3 = new ID3( file, "EUC-KR" );
			trace( "before :", id3.getData( Tag.V2_TITLE ) );
			trace( "before :", id3.getData( Tag.V2_ARTIST ) );
			trace( "before :", id3.getData( Tag.V2_ALBUM ) );
			id3.v1Enabled = false;
			id3.setData( Tag.V2_TITLE, "너랑 나" );
			id3.setData( Tag.V2_ARTIST, "아이유" );
			id3.setData( Tag.V2_ALBUM, "Last Fantasy" );
			id3.flush();
			trace( "after :", id3.getData( Tag.V2_TITLE ) );
			trace( "after :", id3.getData( Tag.V2_ARTIST ) );
			trace( "after :", id3.getData( Tag.V2_ALBUM ) );
		}
	}
}