require "leslie"

local t = leslie.Template([[Hello world - powered by {{ name }} {{ version }}.]])


local s = os.time()
for i = 1,500000 do
    t:render({ name = "Leslie", version = leslie.version })
end
print('500000===>”√ ±35s')
print(os.time() - s)
