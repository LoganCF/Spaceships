module record_history;

import std.stdio;
import std.conv;
import std.file;

import record_keeper;



enum Filemode {read, write, closed}

//interface to a file that holds records from previous games
// file format is:
// num_records, current_record, records...
class RecordHistory 
{
	string _filename;
	File _file;
	Filemode _mode = Filemode.closed;
	
	int _current_record_index; // in file
	int _num_records;    // in file
	
	size_t _record_size;
	uint _num_inputs;

	this( string filename, uint num_inputs)
	{
		_filename = filename;
		_num_inputs = num_inputs;
		//get the size of a completed record, including the array, but not the array pointer
		//TODO: find out if this is actually the size of what gets written
		/+CompletedRecord.classinfo.init.length - (real[]).sizeof+/ 
		_record_size = int.sizeof*4 + real.sizeof*1 + bool.sizeof*1 + real.sizeof*num_inputs;
		//debug
		writefln("record size: %d, real is %d, real[] is %d, completed record is %d",_record_size,real.sizeof, (real[]).sizeof, CompletedRecord.classinfo.init.length);
	}
	
	/+
	this caused crashes
	~this()
	{
		enter_filemode(Filemode.closed);
	}+/
	
	void close()
	{
		enter_filemode(Filemode.closed);
	}
	
	void enter_filemode(Filemode mode)
	{
		if( mode != _mode)
		{	
			leave_filemode();
		
			_mode = mode;
			//setup new mode
			final switch(mode)
			{
			case Filemode.closed:
				//close file
				_file.close();
				break;
			case Filemode.read:
				//_file.open(to!string(_filename),"a+b");
				//grab current_record and num_records (first two vars in the file)
				_file.seek(0,SEEK_SET);
				int[2] input_2_ints;
				_file.rawRead(input_2_ints);
				_num_records = input_2_ints[0];
				_current_record_index = input_2_ints[1];
				//fseek(sizeof(int)*2 + _record_size*_current_record_index);
				_file.seek(int.sizeof*2 + _record_size*_current_record_index, SEEK_SET);
				break;
			case Filemode.write:
				
				// grab num_records
				_file.seek(0,SEEK_SET);
				int[1] input_int;
				_file.rawRead(input_int);
				_num_records = input_int[0];
				// fseek end
				_file.seek(0,SEEK_END);
				break;
			}
		}
	}
	
	//call when closing the file, or switching between reading and writing
	void leave_filemode()
	{
		//cleanup previous mode
		final switch(_mode)
		{
		case Filemode.closed:
			//open file
			bool already_exists = exists(_filename);
			_file.open(to!string(_filename),"a+b");
			if(!already_exists)
			{  
				//put the two leading ints in the file
				_file.seek(0,SEEK_SET);
				_file.rawWrite([0,0]);
			}
			break;
		case Filemode.read:
			// write _current_record_index to file
			_file.seek(int.sizeof,SEEK_SET); // second int in the file
			_file.rawWrite([_current_record_index]);
			write("wrote record index:");
			writeln(_current_record_index);
			//_file.close();
			break;
		case Filemode.write:
			// write _num_records to file
			_file.seek(0,SEEK_SET); // first int in the file
			_file.rawWrite([_num_records]);
			//_file.close();,/
			break;
		}
	}
	
	void add_record_to_file(CompletedRecord recd)
	{
		enter_filemode(Filemode.write);
		
		//debug
		//writefln("Pos is: %d", _file.tell());
		
		recd.write_to_binary(_file);
		
		_num_records ++;
		//TODO:? if it gets too big, start overwriting the old data?
	}
	
	CompletedRecord read_record_from_file()
	{
		enter_filemode(Filemode.read);
		
		//debug
		//writefln("Pos is: %d", _file.tell());
		
		
		//TODO: avoid this copy.
		CompletedRecord retval = CompletedRecord.read_from_binary(_file, _num_inputs);
		
		//debug
		//retval.print();
		
		_current_record_index++;
		if(_current_record_index >= _num_records)
		{
			_current_record_index = 0;
			_file.seek(int.sizeof*2);
		}
		
		return retval; //TODO: avoid this copy, too.
	}
	
	
	void fill_array_to_n_records(ref CompletedRecord[] records, uint n)
	{
		while(records.length < n)
		{
			records ~= read_record_from_file();
		}
	}
	
	
	unittest 
	{
		RecordHistory rhist = new RecordHistory("nets/testhistory",2);

		real[2] real_array;
		real_array[] = 0.5;
		CompletedRecord recd1 = new CompletedRecord(1,0.3,real_array,1,4);
		CompletedRecord recd2 = new CompletedRecord(1,0.3,real_array,1,4);
		rhist.add_record_to_file(recd1);
		rhist.add_record_to_file(recd2);
		
		CompletedRecord result_recd1 = rhist.read_record_from_file();
		CompletedRecord result_recd2 = rhist.read_record_from_file();
		
		rhist.enter_filemode(Filemode.closed);
		
		recd1.print();
		result_recd1.print();
		assert(recd1 == result_recd1);
		write("test1 passed");
		assert(recd2 == result_recd2);
		write("test2 passed");
		
		//TODO: check num_records and current_record
	}
	
}



