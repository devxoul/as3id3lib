package kr.xoul.as3id3lib
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ID3
	{
		//
		// public variables
		//
		
		/** Specified whether the ID3v1 enabled. */
		public var v1Enabled : Boolean;
		
		/** Specified whether the ID3v1 enabled. */
		public var v2Enabled : Boolean;
		
		/** A character set. */
		public var charSet : String = "UTF-8";
		
		/** A minor version of ID3v2. */
		public var id3v2Version : int = 4;
		
		
		//
		// protected variables
		//
		
		/** A music file. */
		protected var _file : File = new File;
		
		/**  */
		protected var _fileStream : FileStream = new FileStream;
		
		/** A binary of music. */
		protected var _byteArray : ByteArray;
		
		/** A dictionary where ID3v1 data is stored. */
		protected var _v1Data : Object;
		
		/** A dictionary where ID3v2Frames are stored. */
		protected var _v2Frames : Object;
		
		/** A size of ID3v2 tag. (include header) */
		protected var _sizeOfTag : int;
		
		
		/**
		 * Contructor.
		 * @param file A music file.
		 * @param charSet A character set.
		 */		
		public function ID3( file : File = null, charSet : String = "UTF-8" )
		{
			this.charSet = charSet;
			if( file ) open( file );
		}
		
		/**
		 * Open a music file.
		 * @param file 
		 * 
		 */		
		public function open( file : File ) : void
		{
			v1Enabled = v2Enabled = false;
			
			_byteArray = new ByteArray;
			_v1Data = {};
			_v2Frames = {};
			_sizeOfTag = 0;
			
			_fileStream.open( _file = file, FileMode.READ );
			
			parse();
		}
		
		/**
		 * Parse ID3 tags.
		 * 
		 */		
		protected function parse() : void
		{
			_fileStream.readBytes( _byteArray, 0, _fileStream.bytesAvailable );
			_byteArray.position = 0;
			
			parseV2();
			parseV1();
		}
		
		/**
		 * Parse ID3v2 tags.
		 * 
		 */		
		protected function parseV2() : void
		{
			if( _byteArray.readUTFBytes( 3 ) != "ID3" )
			{
				v2Enabled = false;
				return;
			}
			
			v2Enabled = true;
			
			_byteArray.position = 6; // size
			_sizeOfTag = unsynchsafe( _byteArray.readUnsignedInt() ) + 10; // include header
			
			while( _byteArray.position < _sizeOfTag )
			{
				var frame : ID3v2Frame = new ID3v2Frame;
				frame.header = _byteArray.readUTFBytes( 4 );
				if( frame.header == "" ) break;
				frame.size = unsynchsafe( _byteArray.readUnsignedInt() );
				_byteArray.position += 3; // flag + null byte
				_byteArray.readBytes( frame.data, 0, frame.size - 1 );
				
				_v2Frames[frame.header] = frame;
				
				continue;
				trace( "header :", frame.header );
				trace( "size   :", frame.size );
				trace( "data   :", frame.data );
				trace( "pos    :", _byteArray.position );
				trace( "---" );
			}
		}
		
		/**
		 * Parse ID3v1 tags.
		 *
		 */		
		protected function parseV1() : void
		{
			_byteArray.position = _byteArray.length - 128;
			if( _byteArray.readUTFBytes( 3 ) != "TAG" )
			{
				v1Enabled = false;
				_v1Data[Tag.V1_SONG_NAME] = "";
				_v1Data[Tag.V1_ARTIST] = "";
				_v1Data[Tag.V1_ALBUM] = "";
				_v1Data[Tag.V1_YEAR] = "";
				_v1Data[Tag.V1_COMMENT] = "";
				_v1Data[Tag.V1_GENRE] = "";
				return;
			}
			
			v1Enabled = true;
			_v1Data[Tag.V1_SONG_NAME] = _byteArray.readMultiByte( 30, charSet );
			_v1Data[Tag.V1_ARTIST] = _byteArray.readMultiByte( 30, charSet );
			_v1Data[Tag.V1_ALBUM] = _byteArray.readMultiByte( 30, charSet );
			_v1Data[Tag.V1_YEAR] = _byteArray.readUTFBytes( 4 );
			_v1Data[Tag.V1_COMMENT] = _byteArray.readMultiByte( 30, charSet );
			_v1Data[Tag.V1_GENRE] = _byteArray.readUTFBytes( 1 );
		}
		
		/**
		 * Get data from dictionary.
		 * @param tag A key for data.
		 * @return Data matching with tag.
		 * 
		 */		
		public function getData( tag : String ) : Object
		{
			if( _v1Data[tag] )
				return _v1Data[tag];
			
			if( _v2Frames[tag] )
			{
				_v2Frames[tag].data.position = 0;
				return _v2Frames[tag].data.readMultiByte( _v2Frames[tag].data.length, charSet );
			}
			
			return null;
		}
		
		/**
		 * 
		 * @param tag
		 * @return 
		 * 
		 */		
		public function getRawData( tag : String ) : ByteArray
		{
			if( _v1Data[tag] )
				return null;
			
			if( _v2Frames[tag] )
				return _v2Frames[tag].data;
			
			return null;
		}
		
		/**
		 * data가 BitmapData일 경우 따로 처리하는 로직 필요
		 * 
		 * @param tag A key for data.
		 * @param data Data to be stored.
		 * @param flush Specified whether call flush() method after set data.
		 * 
		 */		
		public function setData( tag : String, data : String, flush : Boolean = false ) : void
		{
			if( isV1Tag( tag ) )
			{
				v1Enabled = true;
				_v1Data[tag] = data;
			}
			else
			{
				v2Enabled = true;
				
				if( !_v2Frames[tag] )
				{
					_v2Frames[tag] = new ID3v2Frame;
					_v2Frames[tag].header = tag;
				}
				
				_v2Frames[tag].size = getBytes( data );
				_v2Frames[tag].data.length = 0;
				_v2Frames[tag].data.writeMultiByte( data, charSet );
			}
			
			if( flush ) this.flush();
		}
		
		/**
		 * 
		 * @param tag
		 * @param data
		 * @param flush
		 * 
		 */		
		public function setRawData( tag : String, data : ByteArray, flush : Boolean = false ) : void
		{
			data.position = 0;
			
			if( isV1Tag( tag ) )
			{
				return;
			}
			else
			{
				v2Enabled = true;
				
				if( !_v2Frames[tag] )
				{
					_v2Frames[tag] = new ID3v2Frame;
					_v2Frames[tag].header = tag;
				}
				
				_v2Frames[tag].size = data.length;
				_v2Frames[tag].data.length = 0;
				_v2Frames[tag].data.writeBytes( data, 0, data.length );
			}
			
			if( flush ) this.flush();
		}
		
		/**
		 * Save ID3 tags to file.
		 * 
		 */		
		public function flush() : void
		{
			flushV2();
			flushV1();
			
			_fileStream.close();
			_fileStream.open( _file, FileMode.WRITE );
			_fileStream.writeBytes( _byteArray, 0, _byteArray.length );
			_fileStream.close();
			open( _file );
			
			trace( "finish" );
		}
		
		/**
		 * Write ID3v2 tags on _byteArray.<br />
		 * 1. Backup audio data and ID3v1 data to audioAndID3v1Data.
		 * 2. Clear _byteArray.<br />
		 * 3. Write ID3v2 tags on _byteArray.<br />
		 * 4. Write audioAndID3v1Data at end of _byteArray.<br /> 
		 * 
		 */		
		protected function flushV2() : void
		{
			// Audio Frame이 시작되는 위치부터 끝까지 백업해둠
			var audioAndID3v1Data : ByteArray = new ByteArray;
			audioAndID3v1Data.writeBytes( _byteArray, _sizeOfTag, _byteArray.length - _sizeOfTag );
			audioAndID3v1Data.position = 0;
			_byteArray.length = 0;
			
			if( v2Enabled )
			{
				_byteArray.writeUTFBytes( "ID3" );
				_byteArray.writeByte( id3v2Version ); // version
				_byteArray.writeByte( 0 ); // version
				_byteArray.writeByte( 0 ); // flag
				_byteArray.writeInt( 0 ); // size, will be changed after writing id3v2 data
				
				var frame : ID3v2Frame;
				for each( frame in _v2Frames )
				{
					_byteArray.writeUTFBytes( frame.header ); // frame identifier
					_byteArray.writeInt( synchsafe( frame.size + 1 ) ); // size
					_byteArray.writeByte( 0 ); // flag
					_byteArray.writeByte( 0 ); // flag
					_byteArray.writeByte( 0 ); // null byte
					_byteArray.writeBytes( frame.data, 0, frame.data.length );
				}
				
				var totalFrameSize : int = _byteArray.position - 10;
				var num0 : int;
				if( totalFrameSize < 64 )
				{
					num0 = 128 - totalFrameSize;
				}
				else
				{
					for( var i : int = 0;; i++ )
					{
						if( 128 + 64 * i <= totalFrameSize * 2 && totalFrameSize * 2 < 128 + 64 * ( i + 1 ) )
						{
							num0 = 128 + 64 * ( i + 1 ) - totalFrameSize;
							break;
						}
					}
				}
				
				for( i = 0; i < num0; i++ )
					_byteArray.writeByte( 0 );
				
				var size : int = synchsafe( _byteArray.position - 10 ); // size of id3v2 data (except for the header)
				
				_byteArray.writeBytes( audioAndID3v1Data, 0, audioAndID3v1Data.length );
				
				_byteArray.position = 6; // size of tag
				_byteArray.writeInt( size );
			}
			else
			{
				_byteArray.writeBytes( audioAndID3v1Data, 0, audioAndID3v1Data.length );
			}
		}
		
		/**
		 * Write ID3v1 tags on _byteArray after clearing ID3v1 tags.<br />
		 * 
		 */		
		protected function flushV1() : void
		{			
			// delete ID3v1 data
			_byteArray.position = _byteArray.length - 128;
			if( _byteArray.readUTFBytes( 3 ) == "TAG" )
				_byteArray.length -= 128;
			
			_byteArray.position = _byteArray.length;
			
			if( v1Enabled )
			{
				_byteArray.writeUTFBytes( "TAG" );
				
				writeV1WithLength( _v1Data[Tag.V1_SONG_NAME], 30 );
				writeV1WithLength( _v1Data[Tag.V1_ARTIST], 30 );
				writeV1WithLength( _v1Data[Tag.V1_ALBUM], 30 );
				writeV1WithLength( _v1Data[Tag.V1_YEAR], 4 );
				writeV1WithLength( _v1Data[Tag.V1_COMMENT], 30 );
				writeV1WithLength( _v1Data[Tag.V1_GENRE], 1 );
			}
			
		}
		
		
		//
		// Utils
		//
		
		/**
		 * 
		 * @param tag
		 * @return 
		 * 
		 */		
		protected function isV1Tag( tag : String ) : Boolean
		{
			var firstCharCode : int = tag.charCodeAt( 0 );
			if( 97 <= firstCharCode && firstCharCode <= 122 )
				return true;
			return false;
		}
		
		/**
		 * 
		 * @param data
		 * @param length
		 * 
		 */		
		protected function writeV1WithLength( data : String, length : int ) : void
		{
			var dataLen : int = getBytes( data );
			var num0 : int = length - dataLen;
			_byteArray.writeMultiByte( data, charSet );
			for( var i : int = 0; i < num0; i++ )
				_byteArray.writeByte( 0 );
		}
		
		/**
		 * 
		 * @param num
		 * @return 
		 * 
		 */		
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
		
		/**
		 * 
		 * @param num
		 * @return 
		 * 
		 */		
		protected function unsynchsafe( num : int ) : int
		{
			var out : int = 0;
			var mask : int = 0x7F000000;
			
			while( mask ) {
				out >>= 1;
				out |= num & mask;
				mask >>= 8;
			}
			
			return out;
		}
		
		/**
		 * 
		 * @param data
		 * @return 
		 * 
		 */		
		protected function getBytes( data : String ) : uint
		{
			var ba : ByteArray = new ByteArray;
			ba.writeMultiByte( data, charSet );
			return ba.length;
		}
	}
}