class String
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
end

namespace :ssl_dev do
  CERT_DIRECTORY = ENV['HOME'] + '/dev_cert'
  COMMON_NAME = 'vhlcentral.com'
  PKI_DIR = ENV['HOME'] + '/.pki/nssdb'

  desc 'Generate self-signed certificates'
  task :generate_certs, :env do
    Dir.mkdir(CERT_DIRECTORY) unless File.directory?(CERT_DIRECTORY)
    unless (system 'which openssl')
      puts "It looks like you don't have openssl installed.".red.bold
      puts 'sudo apt-get install openssl'.cyan
      next 
    end

    FileUtils.cp('/etc/ssl/openssl.cnf', '/tmp/openssl.cnf')
    domains = ''
    File.foreach('sslhosts').with_index { |l, i| domains << 'DNS.' + i.to_s + ' = ' + l unless l.empty? }

    system "echo '[SAN]\nsubjectAltName = @alt_names\n[alt_names]\n#{domains}' >> /tmp/openssl.cnf"
    system "openssl req -new -x509 -nodes -days 99999 -newkey rsa:2048 -extensions SAN"\
           " -config /tmp/openssl.cnf"\
           " -subj '/C=US/ST=Massachusets/L=Boston/O=VHL/CN=#{COMMON_NAME}' -keyout #{CERT_DIRECTORY}/nginx.key -out #{CERT_DIRECTORY}/nginx.crt"

    puts "New self-signed certificate has been generated at #{CERT_DIRECTORY}.".green
    puts "You probably want to change your nginx site-available configuration and add the following to each side that you need to serve via https \n\n"
    puts 'listen 443 ssl;'
    puts 'ssl on;'
    puts "ssl_certificate #{CERT_DIRECTORY}/nginx.crt;"
    puts "ssl_certificate_key #{CERT_DIRECTORY}/nginx.key;"

  end

  desc 'Delete development certificates'
  task :clean, :env do
    FileUtils.rm_r(CERT_DIRECTORY)
  end

  desc 'Add certs to the local CA chain'
  task :add_cert_to_ca, :env do
    unless (system 'which certutil')
      puts "It looks like you don't have libnss3-tools installed.".red.bold
      puts "sudo apt-get install libnss3-tools".cyan
      next
    end
    
    if not File.directory?(PKI_DIR)
      puts "We didn't find your local PKI db and going to create a new one at '#{PKI_DIR}'.".bold
      FileUtils.mkdir_p(PKI_DIR) 
    end
    
    system 'certutil -d sql:$HOME/.pki/nssdb -N' unless File.exist?(PKI_DIR + '/cert9.db')
    system "certutil -d sql:$HOME/.pki/nssdb -A -t CP,,C -n 'VHL' -i #{CERT_DIRECTORY}/nginx.crt"

    puts "Your self-signed certificate (#{CERT_DIRECTORY}/nginx.crt) has been added to the local CA chain.".green
    puts "This allows the local Chrome browser recognize it as trusted (you have to restart browser).rmj"
    puts "You may want to copy your certificate to your other machines and run ssl_dev:add_cert_to_ca there."
  end

  desc 'Generate self-signed certificates and them to the local CA chain'
  task :certs => [:generate_certs, :add_cert_to_ca]
end
