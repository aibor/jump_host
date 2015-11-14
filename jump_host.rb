# Copyright (C) 2015 aibo <aibo+code@aibor.de>
#
# This work is free. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.
#
# 
# Usage:
#   require 'jump_host'
#
#   # format string for the hostname, %s is replaced with the region
#   JumpHost::Droplet.name_format = "jump-%s.your-do.host"
#
#   # replace with your API key
#   JumpHost::DOApi.token =
#     '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
#
#   # optional, first snapshot taken if this is not set
#   JumpHost::Droplet.default_image_name = "my_jump_host_image"
#
#   JumpHost::DOApi.images.map &:name
#

require 'droplet_kit'

module JumpHost
  class Error < ::StandardError; end

  module DOApi
    include ::DropletKit

    class TokenNotSetError < Error; end

    class << self
      attr_writer :token
    end

    module_function 

    def client(refresh: true)
      if @token
        @client = nil if refresh
        @client ||= Client.new(access_token: @token)
      else
        raise TokenNotSetError
      end
    end

    def images(refresh: false)
      @images = nil if refresh
      @images ||= client.images.all.select { |i| i.public == false }
    end

    def droplets(refresh: false)
      @droplets = nil if refresh
      @droplets ||= client.droplets.all
    end

    def ssh_keys(refresh: false)
      @ssh_keys = nil if refresh
      @ssh_keys ||= client.ssh_keys.all
    end
  end

  module Droplet
    extend self

    class ExistsError < Error; end
    class NotDeployedError < Error; end
    class NameFormatNotSetError < Error; end
    class NoImageFoundError < Error; end

    class << self
      attr_writer :name_format, :default_image_name
    end

    def deploy(region, image_name: nil)
      if exists_at? region
        raise ExistsError
      elsif not image = find_image(image_name)
        raise NoImageFoundError
      else
        droplet = new region, image
        DOApi.client.droplets.create droplet
        show region
      end
    end

    def show(region)
      if droplet = find_at(region, refresh: true)
        return droplet.status, droplet.public_ip
      else
        raise NotDeployedError
      end
    end

    def drop(region)
      if droplet = find_at(region)
        DOApi.client.droplets.delete id: droplet.id
      else
        raise NotDeployedError
      end
    end

    def name(region)
      if @name_format
        @name_format % region
      else
        raise NameFormatNotSetError
      end
    end
    private :name

    def new(region, image)
      ssh_key_ids = DOApi.ssh_keys.map &:id
      options = {
        name: name(region),
        region: region,
        image: image.id,
        size: '512mb',
        ssh_keys: ssh_key_ids
      }

      ::DropletKit::Droplet.new options
    end
    private :new

    def find_at(region, refresh: false)
      DOApi.droplets(refresh: refresh).find do |d|
        d.name == name(region)
      end
    end

    def exists_at?(region, refresh: false)
      !!find_at(region, refresh: refresh)
    end
    private :exists_at?

    def find_image(name)
      images = DOApi.images
      find = lambda { |name| images.find { |i| i.name == name } }

      if name
        find.(name)
      elsif @default_image_name
        find.(@default_image_name)
      else
        images.first
      end
    end
    private :find_image
  end

  extend Droplet 
end
