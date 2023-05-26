local logger = require("logging.logger")

local log = logger.new({
    name = "Leeches",
    logLevel = "DEBUG",
    logToConsole = false,
    includeTimestamp = false,
})

return log
