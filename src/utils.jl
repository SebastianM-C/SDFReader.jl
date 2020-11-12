get_time(file) = open(file) do f
    h = header(file)
    h.time * u"s"
end
