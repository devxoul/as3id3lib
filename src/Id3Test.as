package
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import kr.xoul.as3id3lib.Tag;
	
	public class Id3Test
	{
		private var _fileStream : FileStream = new FileStream;
		private var _byteArray : ByteArray = new ByteArray;
		
		private var _bytes : Array = [];
		
		public function Id3Test()
		{
			var i : int, j : int, len : int;
			
			_fileStream.open( as3id3lib.file , FileMode.UPDATE );
			_fileStream.readBytes( _byteArray, 0, _fileStream.bytesAvailable );
			_byteArray.position = 0;
			
			while( _byteArray.position < _byteArray.length )
			{
				var byte : int = _byteArray.readUnsignedByte();
				_bytes.push( byte );
			}
			
			trace( "bytes :", _bytes );
			trace( "len :", _bytes.length );
			
			log( "ID3" );
			log( "TIT2" );
			log( "V2Title" );
			log( "TPE1" );
			log( "V2Artist" );
			log( "TALB" );
			log( "2222" );
			
			log( "TAG" );
			log( "V1Title" );
			
			trace( "END" );
		}
		
		private function getBytes( str : String ) : Array
		{
			var bytes : Array = [];
			
			for( var i : int = 0, len : int = str.length; i < len; i++ )
			{
				bytes.push( str.charCodeAt( i ) );
			}
			
			return bytes;
		}
		
		private function contain( str : String, original : Array ) : int
		{
			var i : int, j : int, len : int;
			
			var pattern : Array = getBytes( str );
			
			for( i = 0, len = original.length - pattern.length; i < len; i++ )
			{
				for( j = 0; j < pattern.length; j++ )
				{
					if( original[i + j] == pattern[j] )
					{
						if( j == pattern.length - 1 )
							return i;
					}
					else
						break;
				}
			}
			
			return -1;
		}
		
		private function log( str : String ) : void
		{
			trace( str, ":", contain( str, _bytes ), "			| bytes :", getBytes( str ) );
		}
	}
}