package kr.xoul.as3id3lib
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ID3
	{
		/**  */
		protected var _file : File = new File;
		
		/**  */
		protected var _fileStream : FileStream = new FileStream;
		
		/**  */
		protected var _byteArray : ByteArray;
		
		/**  */
		protected var _bytes : Vector.<int>;
				
		protected var _v1Data : Object;
		protected var _v2Data : Object;
		
		protected var v1Enabled : Boolean;
		protected var v2Enabled : Boolean;
		
		
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
			_byteArray = new ByteArray;
			_bytes = new Vector.<int>;
			_v1Data = {};
			_v2Data = {};
			v1Enabled = v2Enabled = false;
			
			_fileStream.open( _file = file, FileMode.READ );
			parse();
		}
		
		protected function parse( byteArray : ByteArray = null ) : void // protected
		{
			if( byteArray ) // tmp
			{// tmp
				trace( "bytearray is exists" ); //tmp
				_byteArray = byteArray;// tmp
				_byteArray.position = 0;//tmp
				_bytes.length = 0; //tmp
			}//tmp
			else//tmp
			{//tmp
				_fileStream.readBytes( _byteArray, 0, _fileStream.bytesAvailable );
				_byteArray.position = 0;
			}//tmp
			
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
			var offset : int = getOffsetFromLast( convertStringToBytes( "TAG" ), _bytes );
			trace( "v1 tag offset :", offset );
			if( offset == -1 ) return;
			v1Enabled = true;
			_byteArray.position = offset + 3;
			_v1Data[Tag.V1_SONG_NAME] = _byteArray.readUTFBytes( 30 );
			_v1Data[Tag.V1_ARTIST] = _byteArray.readUTFBytes( 30 );
			_v1Data[Tag.V1_ALBUM] = _byteArray.readUTFBytes( 30 );
			_v1Data[Tag.V1_YEAR] = _byteArray.readUTFBytes( 4 );
			_v1Data[Tag.V1_COMMENT] = _byteArray.readUTFBytes( 30 );
			_v1Data[Tag.V1_GENRE] = _byteArray.readUTFBytes( 1 );
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
		
		protected function isV1Tag( tag : String ) : Boolean
		{
			var firstCharCode : int = tag.charCodeAt( 0 );
			if( 97 <= firstCharCode && firstCharCode <= 122 )
				return true;
			return false;
		}
		
		public function getData( tag : String ) : Object
		{
			if( isV1Tag( tag ) )
				return _v1Data[tag];
			
			if( _v2Data[tag] ) return _v2Data[tag];
			
			if( getOffset( convertStringToBytes( "ID3" ), _bytes ) == -1 )
				return null;
			
			v2Enabled = true;
			
			var offset : int = getOffset( convertStringToBytes( tag ), _bytes );
			if( offset == -1 ) return null;
			
			_byteArray.position = offset + 4;
			var size : int = _byteArray.readInt(); // Include null-byte
			_byteArray.position += 3; // Flags + 1
			_v2Data[tag] = _byteArray.readUTFBytes( size - 1 );
			return _v2Data[tag];
		}
		
		public function setData( tag : String, data : Object, flush : Boolean = false ) : void
		{
			if( isV1Tag( tag ) )
			{
				v1Enabled = true;
				_v1Data[tag] = data;
			}
			else
			{
				v2Enabled = true;
				_v2Data[tag] = data;
			}
			
			if( flush ) this.flush();
		}
		
		public function flush() : void
		{
			// v1
			var offset : int = getOffsetFromLast( convertStringToBytes( "TAG" ), _bytes );
			
			if( v1Enabled )
			{
				if( offset == -1 ) _byteArray.position = _byteArray.length;
				_byteArray.position = offset;
				
				_byteArray.writeUTFBytes( "TAG" );
				
				writeV1WithLength( _v1Data[Tag.V1_SONG_NAME], 30 );
				writeV1WithLength( _v1Data[Tag.V1_ARTIST], 30 );
				writeV1WithLength( _v1Data[Tag.V1_ALBUM], 30 );
				writeV1WithLength( _v1Data[Tag.V1_YEAR], 4 );
				writeV1WithLength( _v1Data[Tag.V1_COMMENT], 30 );
				writeV1WithLength( _v1Data[Tag.V1_GENRE], 1 );
			}
			else
			{
				_byteArray.length = offset;
			}
			
			
			// v2
			
			var ff : Vector.<int> = new Vector.<int>;
			ff[0] = 0xFF;
			offset = getOffset( ff, _bytes ); // Audio Frame이 시작되는 위치
			trace( "offset :", offset );
			
			// Audio Frame이 시작되는 위치부터 끝까지 백업해둠
			var audioFrameAndID3v1 : ByteArray = new ByteArray;
			audioFrameAndID3v1.writeBytes( _byteArray, offset, _byteArray.length - offset );
			audioFrameAndID3v1.position = 0;
			
			if( v2Enabled )
			{
				// byteArray 초기화 후 ID3v2 태그 입력 한 뒤 audioFrameAndID3v1를 붙임
				_byteArray.length = 0;
				_byteArray.writeUTFBytes( "ID34000000" );
				
				var lastData : String;
				for( var tag : String in _v2Data )
				{
					_byteArray.writeUTFBytes( tag ); // Frame Identifier
					_byteArray.writeUnsignedInt( _v2Data[tag].length + 1 ); // Size, 한글 주의
					_byteArray.writeByte( 0 ); // Flag
					_byteArray.writeByte( 0 ); // Flag
					_byteArray.writeByte( 0 ); // null byte
					_byteArray.writeUTFBytes( _v2Data[tag] );
					lastData = _v2Data[tag];
				}
				
				var num0 : int = 117 - lastData.length; // 한글 주의
				
				for( var i : int = 0; i < num0; i++ )
					_byteArray.writeByte( 0 );
				
				var size : int = synchsafe( _byteArray.position ); // 여기(header)까지의 포지션이 헤더의 크기
				
				_byteArray.writeBytes( audioFrameAndID3v1, 0, audioFrameAndID3v1.length );
				
				_byteArray.position = 6; // size of tag
				_byteArray.writeInt( size );
			}
			else
			{
				_byteArray = audioFrameAndID3v1;
			}
			
			_fileStream.close();
			_fileStream.open( _file, FileMode.WRITE );
			_fileStream.writeBytes( _byteArray, 0, _byteArray.length );
			_fileStream.close();
			open( _file );
			
			trace( "finish" );
		}
		
		protected function writeV1WithLength( data : String, length : int ) : void // 한글 주의
		{
			var dataLen : int = data.length;
			var num0 : int = length - dataLen;
			_byteArray.writeUTFBytes( data );
			for( var i : int = 0; i < num0; i++ )
				_byteArray.writeByte( 0 );
		}
		
		protected function synchsafe( num : int ) : int
		{
			var out : int;
			var mask : int = 0x7F;
			
			while( mask ^ 0x7FFFFFFF )
			{
				out = num & ~mask;
				out <<= 1;
				out |= num & mask;
				mask = ((mask + 1) << 8) - 1;
				num = out;
			}
			
			return out;
		}
	}
}