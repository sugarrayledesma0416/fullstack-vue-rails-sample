require 'erb'

namespace :ci do
  desc "This creates a database configuration file from a template"
  task :config_db do
    unless ENV['DATABASE_SUFFIX'] && ENV['TEMPLATE_NAME']
      puts "usage: rake db:config:build TEMPLATE_NAME=<template_name> DATABASE_SUFFIX=<suffix> [PARALLEL=<true|false(default)>]"
      exit
    end

    database_password = ENV['DATABASE_MYSQL_PASSWORD'] || ''
    database_suffix = ENV['DATABASE_SUFFIX']
    template_name = ENV['TEMPLATE_NAME']
    parallel = (ENV['PARALLEL'].to_s == 'true')

    database_suffix = database_suffix.downcase.gsub(/[^A-Za-z0-9]/, "_")

    parallel_opts   = ''
    parallel_opts   = "<%= ENV['TEST_ENV_NUMBER'] %>" if parallel

    erb_filename = "config/database.#{template_name}.yml.erb"
    output_filename = "config/database.yml"

    erb = ERB.new(File.read(erb_filename))
    File.open(output_filename, "w") do |output|
      output.write(erb.result(binding))
    end

  end
end
