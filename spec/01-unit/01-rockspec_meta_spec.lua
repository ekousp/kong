local pl_dir = require "pl.dir"
local pl_path = require "pl.path"
local meta = require "kong.meta"

describe("rockspec/meta", function()
  local rock, lua_srcs = {}
  local rock_filename

  setup(function()
    lua_srcs = pl_dir.getallfiles("./kong", "*.lua")
    assert.True(#lua_srcs > 0)
    local res = pl_dir.getfiles(".", "kong-*.rockspec")
    assert.equal(1, #res)
    rock_filename = res[1]
    local f = assert(loadfile(res[1]))
    setfenv(f, rock)
    f()
  end)

  describe("meta", function()
    it("has a _NAME field", function()
      assert.is_string(meta._NAME)
    end)
    it("has a _VERSION field", function()
      assert.is_string(meta._VERSION)
      assert.matches("%d+%.%d+%.%d+", meta._VERSION)
    end)
    it("has a _VERSION_TABLE field", function()
      assert.is_table(meta._VERSION_TABLE)
      assert.is_number(meta._VERSION_TABLE.major)
      assert.is_number(meta._VERSION_TABLE.minor)
      assert.is_number(meta._VERSION_TABLE.patch)
      -- pre_release optional
    end)
    it("has a _DEPENDENCIES field", function()
      assert.is_table(meta._DEPENDENCIES)
      assert.is_table(meta._DEPENDENCIES.nginx)
      assert.is_table(meta._DEPENDENCIES.serf)
    end)
  end)

  it("has same version as meta", function()
    assert.matches(meta._VERSION, rock.version:match("(.-)%-.*$"))
  end)
  it("has same name as meta", function()
    assert.equal(meta._NAME, rock.package)
  end)
  it("has correct version in filename", function()
    local pattern = meta._VERSION:gsub("%.", "%%."):gsub("-", "%%-")
    assert.matches(pattern, rock_filename)
  end)

  describe("modules", function()
    it("are all included in rockspec", function()
      for _, src in ipairs(lua_srcs) do
        src = src:sub(3) -- strip './'
        local found
        for mod_name, mod_path in pairs(rock.build.modules) do
          if mod_path == src then
            found = true
            break
          end
        end
        assert(found, "could not find module entry for Lua file: "..src)
      end
    end)
    it("all modules named as their path", function()
      for mod_name, mod_path in pairs(rock.build.modules) do
        if mod_name ~= "kong" then
          mod_path = mod_path:gsub("%.lua", ""):gsub("/", '.'):gsub("%.init", "")
          assert(mod_name == mod_path, mod_path.." has different name ("..mod_name..")")
        end
      end
    end)
    it("all rockspec files do exist", function()
      for mod_name, mod_path in pairs(rock.build.modules) do
        assert(pl_path.exists(mod_path), mod_path.." does not exist ("..mod_name..")")
      end
    end)
  end)
end)
