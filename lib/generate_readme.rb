File.open(File.expand_path("../../README.md", __FILE__), "w") do |f|
  first_comment = []
  IO.read(File.expand_path("../params_matching.rb", __FILE__)).each_line do |l|
    if l =~ /\s*#/
      first_comment << l.sub(/^\s*#\s/, "").rstrip
    elsif !first_comment.empty?
      break
    end
  end
  f.write(first_comment.join("\n"))
end