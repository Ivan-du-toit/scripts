require 'yaml'
require 'fileutils'
require 'optparse'


config_file = 'config.yaml'

default_config = {
    'rules' => [
        {
            'source'  => 'folderThatContainsFilesToBeMoved',
            'dest'    => 'moved',
            'match'   => 'textThatShouldBeReplaced',
            'replace' => 'textThatWillReplaceIt',
            'action'  => 'move'
        }, {
            'source'  => '.',
            'dest'    => 'deep/file/path',
            'match'   => '([0-9]*)',
			'replace' => '\1',
            'action'  => 'copy'
        }
    ]
}

# TODO: Make the config file location configurable by passing it in as a optional paramater.
# TODO: Add param to generate the source DIR list from a directory structure.

options = {}
verbose = false
OptionParser.new do |opts|
    opts.banner = "Usage: dogPile.rb [options]"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        verbose = v
    end

    opts.on("--config [FILE]", String, "Config file location") do |c|
        config_file = c
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

sources = ["."]

unless File.exists?(config_file)
    YAML.dump(default_config)
    File.open(config_file, 'w') {|f| f.write default_config.to_yaml }
    puts "No config file found, generating example config to config.yaml"
    exit
end

config = YAML.load_file(config_file)
if verbose
    puts "Config: "
    puts config
end

rules = []
for rule in config["rules"] do
    rule["match"] = Regexp.new(rule["match"])
    rules.push(rule)
end

matches = 0

sources.each do |sourceDir|
    rules.each do | rule |
        #unless Dir.exists?(sourceDir + "/" + rule["source"])
        unless File.exists?(sourceDir + "/" + rule["source"])
            puts rule
            raise "Source folder does not exist for: " + sourceDir + "/" + rule["source"]
        end

        Dir.glob(sourceDir + "/" + rule["source"] + "/*.*").each do |original_file|
            file_name = File.basename(original_file, File.extname(original_file)) + File.extname(original_file)
            if rule["match"].match(file_name)
                new_file_name = file_name.gsub(rule["match"], rule["replace"])

                matches = matches +1

                unless File.exists?(sourceDir + "/" + rule["dest"])
                #unless Dir.exists?(sourceDir + "/" + rule["dest"])
                    if verbose
                        puts "Creating dir: " + rule["dest"]
                    end
                    Dir.mkdir(sourceDir + "/" + rule["dest"])
                end

                fullSourcePath = sourceDir + "/" + rule["source"] + "/" + file_name
                fullDestPath = sourceDir + "/" + rule["dest"] + "/" + new_file_name
                if rule["action"] == "move"
                    if verbose
                        puts "Moving " + fullSourcePath + " to " + fullDestPath
                    end
                    File.rename(fullSourcePath, fullDestPath)
                elsif rule["action"] == "copy"
                    if  verbose
                        puts "Copying " + fullSourcePath + " to " + fullDestPath
                    end
                    FileUtils.cp(fullSourcePath, fullDestPath)
                else
                    warn "Invalid action on rule"
                end

            end
        end
    end
end

if verbose
    puts "#{matches} files matches"
    puts "Renaming complete!"
end
