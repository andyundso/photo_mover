require 'exif'
require 'exifr/tiff'
require 'fileutils'
require 'time'

def parse_exif_data(date)
  begin
    Time.strptime(date, '%Y:%m:%d %H:%M:%S')
  rescue StandardError
    nil
  end
end

def write_log(message)
  File.write("#{ARGV[1]}/moving.log", "#{message}\n", mode: 'a')
end

unless ARGV[0]
  puts 'No base path given!'
  exit
end

unless ARGV[1]
  puts 'No base path given where folder should be created!'
  exit
end

all_files_names = Dir["#{ARGV[0]}/*"]

all_files_names.each do |path_of_photo|
  next if File.directory?(path_of_photo) || !path_of_photo

  array_of_dates = []

  photo_file = File.open(path_of_photo)
  array_of_dates << photo_file.atime
  array_of_dates << photo_file.ctime
  array_of_dates << photo_file.mtime

  begin
    if File.extname(path_of_photo) == '.CR2'
      array_of_dates << EXIFR::TIFF.new(path_of_photo).date_time
    else
      photo_data = Exif::Data.new(File.open(path_of_photo))
      array_of_dates << parse_exif_data(photo_data.date_time_digitized)
      array_of_dates << parse_exif_data(photo_data.date_time_original)
      array_of_dates << parse_exif_data(photo_data.date_time)
    end
  rescue Exif::NotReadable
    write_log("#{path_of_photo} does not include any EXIF data!")
  end

  min_date_of_file = array_of_dates.compact.min
  folder_name = min_date_of_file.strftime("%Y-%m")

  if path_of_photo.include? folder_name
    message = "#{File.basename(path_of_photo)} is already in the correct folder!"
    puts message
    write_log(message)
    next
  end

  target_directory_of_photo = "#{ARGV[1]}/#{folder_name}"

  Dir.mkdir(target_directory_of_photo) unless Dir.exist?(target_directory_of_photo)
  FileUtils.mv(path_of_photo, target_directory_of_photo)

  message = "Successfully moved #{File.basename(path_of_photo)} to folder #{folder_name}."
  puts message
  write_log(message)
end
