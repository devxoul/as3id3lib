package
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import kr.xoul.as3id3lib.ID3;
	import kr.xoul.as3id3lib.Tag;
	
	public class as3id3lib extends Sprite
	{
		public var file : File = new File().resolvePath( "/Users/xoul/Flash/Libraries/as3id3lib/examples/iu.mp3" );
		
		public function as3id3lib()
		{
			var loader : URLLoader = new URLLoader;
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load( new URLRequest( "http://i1.daumcdn.net/cfile2/S200x200/205A124F4ED433CC1675A8" ) );
			loader.addEventListener( Event.COMPLETE, onComplete );
		}
		
		private function onComplete( e : Event ) : void
		{
			var imgarr : ByteArray = e.target.data as ByteArray;
			
			var id3 : ID3 = new ID3( file, "EUC-KR" );
			
			trace( "before ---" );
			trace( "title :", id3.getData( Tag.V2_TITLE ) );
			trace( "artist :", id3.getData( Tag.V2_ARTIST ) );
			trace( "album :", id3.getData( Tag.V2_ALBUM ) );
			trace( "comment", id3.getData( Tag.V2_COMMNET ) );
			trace( "lyrics :", id3.getData( Tag.V2_UNSYNCHRONIZED_LYRICS ) );
			
			id3.setData( Tag.V2_TITLE, "너랑 나" );
			id3.setData( Tag.V2_ARTIST, "아이유" );
			id3.setData( Tag.V2_ALBUM, "Last Fantasy" );
			
			var ba : ByteArray = new ByteArray;
			ba.writeMultiByte( "eng", id3.charSet );
			ba.writeByte( 0 );
			ba.writeMultiByte( "Lyrics\nTest\nzazz", id3.charSet );
			id3.setRawData( Tag.V2_UNSYNCHRONIZED_LYRICS, ba );
			
			ba.position = 0;
			ba.writeMultiByte( "eng", id3.charSet );
			ba.writeByte( 0 );
			ba.writeMultiByte( "this is comment\nkkk", id3.charSet );
			id3.setRawData( Tag.V2_COMMNET, ba );
			
			ba.position = 0;
			ba.writeMultiByte( "image/jpeg", id3.charSet );
			ba.writeByte( 0 );
			ba.writeByte( 0 );
			ba.writeByte( 0 );
			ba.writeBytes( imgarr, 0, imgarr.length );
			id3.setRawData( "APIC", ba );
			
//			id3.v2Enabled = false;
			id3.flush();
			
			trace();
			trace( "after ---" );
			trace( "title :", id3.getData( Tag.V2_TITLE ) );
			trace( "artist :", id3.getData( Tag.V2_ARTIST ) );
			trace( "album :", id3.getData( Tag.V2_ALBUM ) );
			trace( "comment", id3.getData( Tag.V2_COMMNET ) );
			trace( "lyrics :", id3.getData( Tag.V2_UNSYNCHRONIZED_LYRICS ) );
		}
	}
}