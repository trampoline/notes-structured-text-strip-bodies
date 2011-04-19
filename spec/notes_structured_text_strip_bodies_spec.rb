require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe NotesStructuredTextStripBodies do
  describe "strip_files" do
    it "should call strip_file once per input_file with one input file" do
      output_dir = Object.new
      stub(File).directory?(output_dir){true}

      input_file_glob = Object.new
      input_file = Object.new

      stub(Dir).[](input_file_glob){[input_file]}
      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_file)
      NotesStructuredTextStripBodies.strip_files(output_dir, input_file_glob)
    end

    it "should call strip_file once per input_file with multiple input files" do
      output_dir = Object.new
      stub(File).directory?(output_dir){true}

      input_file_globs = [Object.new, Object.new]
      input_files = [Object.new, Object.new]
      stub(Dir).[](input_file_globs[0]){[input_files[0]]}
      stub(Dir).[](input_file_globs[1]){[input_files[1]]}

      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[0])
      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[1])
      NotesStructuredTextStripBodies.strip_files(output_dir, input_file_globs)
    end

    it "should expand globs in the input_files" do
      output_dir = Object.new
      stub(File).directory?(output_dir){true}

      input_file_globs = [Object.new, Object.new]
      input_files = [Object.new, Object.new, Object.new, Object.new]
      stub(Dir).[](input_file_globs[0]){[input_files[0], input_files[1]]}
      stub(Dir).[](input_file_globs[1]){[input_files[2], input_files[3]]}

      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[0])
      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[1])
      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[2])
      mock(NotesStructuredTextStripBodies).strip_file(output_dir, input_files[3])
      NotesStructuredTextStripBodies.strip_files(output_dir, input_file_globs)
    end
  end
  
  describe "strip_file" do
    it "should open a new output file for writing, the input file for reading and call strip" do
      output_dir = "/foo/bar"
      input_file = "baz/boo.txt"
      mock(File).file?("baz/boo.txt"){true}

      logger = Object.new
      stub(NotesStructuredTextStripBodies).logger{logger}

      output_stream = Object.new
      mock(File).open("/foo/bar/boo.txt", "w") do |f, mode, block|
        block.call(output_stream)
      end

      input_stream = Object.new
      mock(File).open("baz/boo.txt", "r") do |f, mode, block|
        block.call(input_stream)
      end

      mock(logger).info(anything){|msg|
        msg.should =~ %r{/foo/bar/boo.txt}
        msg.should =~ %r{baz/boo.txt}
      }
      mock(NotesStructuredTextStripBodies).strip(output_stream, input_stream)

      NotesStructuredTextStripBodies.strip_file(output_dir, input_file)
    end
  end

  describe "readblock" do
    it "should return lines read from a stream until the first empty line" do
      input = <<-EOF
foo
bar

baz
boo
EOF
      io = StringIO.new(input)
      NotesStructuredTextStripBodies.read_block(io).should == ["foo", "bar"]
      NotesStructuredTextStripBodies.read_block(io).should == ["baz", "boo"]
    end

    it "should return nil if the input stream is at EOF" do
      io = StringIO.new("foo\nbar")
      NotesStructuredTextStripBodies.read_block(io).should == ["foo", "bar"]
      NotesStructuredTextStripBodies.read_block(io).should == nil
    end
  end

  describe "is_header_block?" do
    it "should return true if the block contains a line which start with '$MessageID: ' " do
      NotesStructuredTextStripBodies.is_header_block?( ["foo", "$MessageID: bar", "baz"] ).should == true
    end

    it "should return false if there are no lines starting with '$MessageID: ' in the block" do
      NotesStructuredTextStripBodies.is_header_block?( ["foo", "bar", "baz"] ).should == false
    end

    it "should not be case-sensitive" do
      NotesStructuredTextStripBodies.is_header_block?( ["foo", "$MESSAGEID: bar", "baz"] ).should == true
      NotesStructuredTextStripBodies.is_header_block?( ["foo", "$messageID: bar", "baz"] ).should == true
      NotesStructuredTextStripBodies.is_header_block?( ["foo", "$messageid: bar", "baz"] ).should == true
    end
  end
  
  describe "strip" do
    it "should write each line of each header block to output" do
      output = Object.new
      input = Object.new

      block1 = [Object.new, Object.new, Object.new]
      block2 = [Object.new, Object.new, Object.new]
      block3 = [Object.new, Object.new]

      blocks = [block3, block2, block1]
      stub(NotesStructuredTextStripBodies).read_block(input){
        raise "no more blocks" if !blocks
        blocks = nil if blocks.empty?
        blocks.pop if blocks
      }
      
      mock(NotesStructuredTextStripBodies).is_header_block?(block1){true}
      mock(NotesStructuredTextStripBodies).is_header_block?(block2){false}
      mock(NotesStructuredTextStripBodies).is_header_block?(block3){true}

      mock(output).<<(block1[0]){output}
      mock(output).<<("\n").times(5){output}
      mock(output).<<(block1[1]){output}
      mock(output).<<(block1[2]){output}
      mock(output).<<(block3[0]){output}
      mock(output).<<(block3[1]){output}

      NotesStructuredTextStripBodies.strip(output, input)
    end
  end
end
