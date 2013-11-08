#About
   Lua template engine like Django template language

#Wath has done by toontong
  - support {% if not values %}; 
  - make test case 100%.
  - make luajit supported.
  - make Leslie run in [Openresty](http://openresty.org/)
  - make some Filters supported.
  - add cached in leslie.loader, maybe has some issue. If no cached,It will make openresty CPU 100% on the ab bench test.

#TODO: 
  - support: {% if var1 and var2 %}, if {% if var == 1 %}
  - change render from string to function.

#Other template engine using Lua:
  - [moochine](https://github.com/appwilldev/moochine)
  - [stl2](https://github.com/henix/slt2)
  - [lutem](https://github.com/daly88/lutem)
  - [LuaWeb](https://github.com/torhve/LuaWeb)

-----
Leslie dependencies:

- lua 5.1
- lpeg library
- class library (modified version included in package)

Supported tags:

- block
- comment
- empty
- extends
- for
- firstof
- include
- if (partly)
- ifequal
- ifnotequal
- ssi
- templatetag
- with


Filters are currently not supported.

For more information about using Django template language see
http://docs.djangoproject.com/en/dev/ref/templates/builtins/
