require "concurrent"

dataset_dir = File.expand_path(ARGV[0])
indexes = ARGV[1]&.split(",")&.map(&:to_i)

DatasetValidator.new(dataset_dir).validate!(indexes: indexes)
