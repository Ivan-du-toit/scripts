require 'yaml'
require 'fileutils'

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
            'match'   => '[0-9]*',
            'action'  => 'copy'
        }
    ]
}

unless File.exists?(config_file)
    YAML.dump(default_config)
    File.open(config_file, 'w') {|f| f.write default_config.to_yaml }
    puts "No config file found, generating example config to config.yaml"
    exit
end

# TODO: Make the config file location configurable by passing it in as a optional paramater.
# TODO: Add a verbose flag and suppress the output if it is missing.
# TODO: Add param to generate the source DIR list from a directory structure.

verbose = false

if ARGV.length == 0
    sources.push(".")
else
    ARGV.each do |arg|
        sources.push(arg)
    end
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
sources = []

sources.each do |sourceDir|
    rules.each do | rule |
        unless Dir.exists?(sourceDir + "/" + rule["source"])
            puts rule
            raise "Source folder does not exist for: " + sourceDir + "/" + rule["source"]
        end

        Dir.glob(sourceDir + "/" + rule["source"] + "/*.*").each do |original_file|
            file_name = File.basename(original_file, File.extname(original_file)) + File.extname(original_file)
            if rule["match"].match(file_name)
                new_file_name = file_name.gsub(rule["match"], rule["replace"])

                matches = matches +1

                unless Dir.exists?(sourceDir + "/" + rule["dest"]) 
                    if verbose
                        puts "Creating dir: " + rule["dest"]
                    end
                    Dir.mkdir(sourceDir + "/" + rule["dest"])
                end

                if rule["action"] == "move"
                    if verbose
                        puts "Moving " + sourceDir + "/" + rule["source"] + "/" + file_name + " to " + sourceDir + "/" + rule["dest"] + "/" + new_file_name
                    end
                    File.rename(sourceDir + "/" + rule["source"] + "/" + file_name, sourceDir + "/" + rule["dest"] + "/" + new_file_name)
                elsif rule["action"] == "copy"
                    if  verbose
                        puts "Copying " + sourceDir + "/" + rule["source"] + "/" + file_name + " to " + sourceDir + "/" + rule["dest"] + "/" + new_file_name
                    end
                    FileUtils.cp(sourceDir + "/" + rule["source"] + "/" + file_name, sourceDir + "/" + rule["dest"] + "/" + new_file_name)
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

