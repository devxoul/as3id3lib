package kr.xoul.as3id3lib
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ID3
	{
		/**  */
		protected var _fileStream : FileStream = new FileStream;
		
		/**  */
		protected var _byteArray : ByteArray = new ByteArray;
		
		/**  */
		protected var _bytes : Vector.<int> = new Vector.<int>;
		
		/** id3 data. */
		protected var _data : Object = {};
		
		
		/**
		 * Contructor.
		 * @param file
		 * 
		 */		
		public function ID3( file : File = null )
		{
			if( file ) open( file );
		}
		
		/**
		 * Open music file.
		 * @param file 
		 * 
		 */		
		public function open( file : File ) : void
		{
			_fileStream.open( file, FileMode.UPDATE );
			parse();
		}
		
		protected function parse() : void
		{
			_fileStream.readBytes( _byteArray, 0, _fileStream.bytesAvailable );
			_byteArray.position = 0;
			
			while( _byteArray.position < _byteArray.length )
			{
				var byte : int = _byteArray.readUnsignedByte();
				_bytes.push( byte );
			}
			
			parseV1();
		}
		
		
		/**
		 * ID3v1은 먼저 파싱해놓고, v2는 getData를 호출할 때마다 파싱해서 저장해놓는다.
		 * 
		 */		
		protected function parseV1() : void
		{
			_byteArray.position = getOffsetFromLast( convertStringToBytes( "TAG" ), _bytes ) + 3;
			_data[Tag.V1_SONG_NAME] = _byteArray.readUTFBytes( 30 );
			_data[Tag.V1_ARTIST] = _byteArray.readUTFBytes( 30 );
			_data[Tag.V1_ALBUM] = _byteArray.readUTFBytes( 30 );
			_data[Tag.V1_YEAR] = _byteArray.readUTFBytes( 4 );
			_data[Tag.V1_COMMENT] = _byteArray.readUTFBytes( 30 );
			_data[Tag.V1_GENRE] = _byteArray.readUTFBytes( 1 );
		}
				
		
		/**
		 * 
		 * @param str
		 * @return 
		 * 
		 */		
		protected function convertStringToBytes( str : String ) : Vector.<int>
		{
			var bytes : Vector.<int> = new Vector.<int>;
			
			for( var i : int = 0, len : int = str.length; i < len; i++ )
				bytes.push( str.charCodeAt( i ) );
			
			return bytes;
		}
		
		/**
		 * 
		 * @param pattern
		 * @param original
		 * @return 
		 * 
		 */		
		protected function getOffset( pattern : Vector.<int>, original : Vector.<int>, startAt : int = 0 ) : int
		{
			for( var i : int = startAt, len : int = original.length - pattern.length; i < len; i++ )
			{
				for( var j : int = 0; j < pattern.length; j++ )
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
		
		protected function getOffsetFromLast( pattern : Vector.<int>, original : Vector.<int> ) : int
		{
			for( var i : int = original.length - pattern.length; i >= 0; i-- )
			{
				for( var j : int = 0; j < pattern.length; j++ )
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
		
		
		public function getData( tag : String ) : Object
		{
			var firstCharCode : int = tag.charCodeAt( 0 );
			
			// v1 태그를 요구하거나 저장된 v2 태그 정보가 있을 경우
			if( 97 <= firstCharCode && firstCharCode <= 122 || _data[tag] )
				return _data[tag];
			
			var offset : int = getOffset( convertStringToBytes( tag ), _bytes );
			if( offset == -1 ) return null;
			
			_byteArray.position = offset + 4;
			var size : int = _byteArray.readInt(); // Include null-byte
			_byteArray.position += 3; // Flags + 1
			_data[tag] = _byteArray.readUTFBytes( size - 1 );
			return _data[tag];
		}
		
		public function setData( tag : String, data : Object, flush : Boolean = false ) : void
		{
			_data[tag] = data;
			if( flush ) this.flush();
		}
		
		public function flush() : void
		{
			// write to file
		}
	}
}