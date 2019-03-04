# wie im README erwähnt, befinden sich zwei "Exif"-Leser Bibliotheken in diesen Projekt
# EXIF bietet den einfacheren Syntax, kann aber keine CR2-Foto-Dateien lesen
# Dies kann wiederum EXIFR, aber der Syntax unterscheidet sich stark zwischen dem Lesen von JPG und TIFF-Dateien
require 'exif'
require 'exifr/tiff'
require 'fileutils'
require 'time'

# Die EXIF-Bibliothek kann das Datum im EXIF-Format nicht direkt umwandeln in ein Ruby-Time-Objekt
# Daher erledigen wir dies hier manuell
# Sollte ein Fehler beim Lesen passieren, weil z.B. das Bearbeitungsdatum auf der Datei nicht gesetzt ist
# Wird der Fehler abgefangen und einfach nil zurückgegeben
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

# Wie im Readme erwähnt, verlangt das Skript zwei Parameter
# Der erste Parameter ist der Pfad mit den Dateien, welche einsortiert werden sollten
# Der zweite Parameter ist der Pfad, wo die Dateien einsortiert werden sollen
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
  # Sollte sich im Ordner noch weitere Ordner befinden, werden diese hier übersprungen
  next if File.directory?(path_of_photo) || !path_of_photo

  array_of_dates = []

  # Hier lesen wir die drei "Standard-Daten" ein, welche auf einer Datei zu finden sind: Letzter Zugriff, Erstellt Am und Zuletzt geändert
  photo_file = File.open(path_of_photo)
  array_of_dates << photo_file.atime
  array_of_dates << photo_file.ctime
  array_of_dates << photo_file.mtime

  begin
    # Wie oben erwähnt, wird, um das Aufnahme-Datum aus der CR2-Datei zu lesen, die EXIFR-Bibliothek angesprochen
    if File.extname(path_of_photo) == '.CR2'
      array_of_dates << EXIFR::TIFF.new(path_of_photo).date_time
    else
      # Je nach Bild befinden sich mehrere verschiedene Daten auf einem Foto
      # Damit sicher alle eingelesen werden, versuchen wir auch alle auszulesen
      photo_data = Exif::Data.new(File.open(path_of_photo))
      array_of_dates << parse_exif_data(photo_data.date_time_digitized)
      array_of_dates << parse_exif_data(photo_data.date_time_original)
      array_of_dates << parse_exif_data(photo_data.date_time)
    end
  rescue Exif::NotReadable
    write_log("#{path_of_photo} does not include any EXIF data!")
  end

  # Hier entfernen wir allfällige nil-Einträge aus dem Array mit allen Daten, die sich auf dem Foto befinden
  # Und wählen nachher das kleinste Time-Objekt aus, den dieses ist das, wohin das Foto später kommen soll
  min_date_of_file = array_of_dates.compact.min
  folder_name = min_date_of_file.strftime("%Y-%m")

  # Hier wird geprüft, ob das Foto allenfalls schon im korrekten Ordner ist
  if File.dirname(path_of_photo).include? folder_name
    message = "#{File.basename(path_of_photo)} is already in the correct folder (#{folder_name})!"
    puts message
    write_log(message)
    next
  end

  target_directory_of_photo = "#{ARGV[1]}/#{folder_name}"

  # Hier wird der eruierte Zielordner erstellt, falls er noch nicht existiert, und das Foto wird dorthin verschoben.
  Dir.mkdir(target_directory_of_photo) unless Dir.exist?(target_directory_of_photo)
  FileUtils.mv(path_of_photo, target_directory_of_photo)

  message = "Successfully moved #{path_of_photo} to folder #{folder_name}."
  puts message
  write_log(message)
end
