# Dropbox Shares

#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'pp'

class Member
	def initialize(name, email, access_type)
		@name = name
		@email = email
		@access_type = access_type
	end

	def display
		"#{@access_type}:#{@name} (#{@email})"
	end

end

class SharedFolders

	def initialize(key)
		@key = key
	end

	def list_folders(options)
		params = { "limit": 1000, "actions": [] }

		data = http_post("https://api.dropboxapi.com/2/sharing/list_folders", params)
		unless data["entries"].nil?
			
			puts "#{data["entries"].count} shared folders" if options.verbose

			total_shared_with = 0
			total_owner = 0
			total_editor = 0
			total_viewer = 0
			total_mounted = 0
			total_unmounted = 0

			data["entries"].each do |shared_folder|
				name = shared_folder["name"]
				path_lower = shared_folder["path_lower"]
				access_type = shared_folder["access_type"][".tag"]
				shared_folder_id = shared_folder["shared_folder_id"]

				if path_lower
					total_mounted += 1
				else
					total_unmounted += 1
				end

				if (path_lower.nil? && options.unmounted) ||
					(path_lower && options.mounted)
					case access_type
					when "owner"
						total_owner += 1
					when "editor"
						total_editor += 1
					when "viewer", "viewer_no_comment"
						total_viewer += 1
					end

					if (access_type == "owner" && options.owner) ||
						(access_type == "editor" && options.editor) ||
						(access_type == "viewer" && options.viewer) ||
						(access_type == "viewer_no_comment" && options.viewer) 
					members = members_of_shared_folder(shared_folder_id)
						if members.map{|m| m.display}.join().include?(options.shared_with)
							total_shared_with += 1
							if path_lower.nil?
								puts "#{name} - #{access_type} - #{members.map{|m| m.display }.join(', ')}"
							else
								puts "#{path_lower} - #{access_type} - #{members.map{|m| m.display }.join(', ')}"
							end
						end
					end
				end
			end

			puts "#{total_mounted} mounted, #{total_unmounted} unmounted" if options.verbose
			puts "#{total_owner} owner, #{total_editor} editor, #{total_viewer} viewer" if options.verbose
			puts "#{total_shared_with} shared with #{options.shared_with}" unless options.shared_with == "" if options.verbose
		end
	end

	def members_of_shared_folder(shared_folder_id)
		params = { 
			"shared_folder_id": shared_folder_id,
			"limit": 1000,
			"actions": []
			 }

		data = http_post("https://api.dropboxapi.com/2/sharing/list_folder_members", params)

		members = []
		data["users"].each do |user|
			access_type = user["access_type"][".tag"]
			name = user["user"]["display_name"]
			email = user["user"]["email"]
			members << Member.new(name, email, access_type)
		end

		members
	end

	def http_post(url, params)
		uri = URI(url)
		request = Net::HTTP::Post.new(uri.path)

		request['Content-Type'] = 'application/json'
		request['Accept'] = 'application/json'
		request['Authorization'] = "Bearer #{@key}"

		request.body =  params.to_json

		http = Net::HTTP.new(uri.host,uri.port)
		http.use_ssl = true

		response = http.request(request)
		if response.code == "200"
			JSON.parse(response.body)
		else
			puts response.code
			puts response.body
			{}
		end
	end

	def self.parse(args)

		options = OpenStruct.new
		options.shared_with = ""
		options.owner = false
		options.editor = false
		options.viewer = false
		options.unmounted = false
		options.mounted = true
		options.verbose = false

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: dropbox_shares.rb [options]"
			opts.separator ""
			opts.separator "Ensure an access token for Dropbox is stored in environmental variable DROPBOX_ACCESS_TOKEN."
			opts.separator ""
			opts.separator "Specific options:"

			opts.on('-w', '--with=[NAME]', "Filter folders shared with users named") do |name|
				options.shared_with = name unless name.nil?
			end

			opts.on("-o", "--[no-]owner", "Shares you are owner of") do |o|
				options.owner = o
			end

			opts.on("-v", "--[no-]viewer", "Shares you are viewer of") do |v|
				options.viewer = v
			end

			opts.on("-e", "--[no-]editor", "Shares you are editor of") do |e|
				options.editor = e
			end

			opts.on("-u", "--[no-]unmounted", "Include unmounted shares") do |u|
				options.unmounted = u
			end

			opts.on("-m", "--[no-]mounted", "Include mounted shares") do |m|
				options.mounted = m
			end

			opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end

			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

			opts.on_tail("--version", "Show version") do
				puts "0.1"
				exit
			end
		end

		opt_parser.parse!(args)
		options
	end
end

options = SharedFolders.parse(ARGV)
pp options

sf = SharedFolders.new(ENV['DROPBOX_ACCESS_TOKEN'])
sf.list_folders(options)
