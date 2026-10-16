-- :Telescope ssh_files
return require('telescope').register_extension({ exports = { ssh_files = require('config.ssh_files').pick } })
