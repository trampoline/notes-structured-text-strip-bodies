module NotesStructuredTextStripBodies
  class << self
    attr_accessor :logger
  end

  module_function

  def log
    yield logger if logger
  end

  def strip_files(output_dir, input_files, options={})
    log{|logger| logger.info("stripping to output directory: #{output_dir}")}
    input_files = [*input_files]
    input_files.each do |input_file|
      strip_file(output_dir, input_file)
    end
  end

  def strip_file(output_dir, input_file, options={})
    output_file = File.join(output_dir, File.basename(input_file))
    raise "<input_file>: #{input_file} does not exist or is not a regular file" if !File.file?(input_file)
    File.open(input_file, "r") do |input|
      File.open(output_file, "w") do |output|
        log{|logger| logger.debug("stripping: #{input_file} => #{output_file}")}
        strip(output, input)
      end
    end
  end

  def read_block(input)
    return nil if input.eof?
    block = []
    begin
      l = input.readline.chomp
      block << l if l.length>0
    end while !input.eof? && l != ""
    block
  end

  def is_header_block?(block)
    !!block.find{|l| l =~ /^\$MessageID: /}
  end

  def strip(output, input)
    while block=read_block(input)
      block.each{|l| output << l << "\n"} if is_header_block?(block)
    end
  end
end
