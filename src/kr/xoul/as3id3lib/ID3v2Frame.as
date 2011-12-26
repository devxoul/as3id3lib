package kr.xoul.as3id3lib
{
	import flash.utils.ByteArray;

	public class ID3v2Frame
	{
		/** A frame identifier. */
		public var header : String;
		
		/** A size of data. */
		public var size : int;
		
		/** Tag data. */
		public var data : ByteArray;
		
		public function ID3v2Frame()
		{
			data = new ByteArray;
		}
	}
}