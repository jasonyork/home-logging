#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'
require 'dotenv'
Dotenv.load

Daemons.run('main.rb')
