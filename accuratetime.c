#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <math.h>
#include <time.h>


static int accurate_clock(lua_State *L)
{
    struct timespec spec;
    
    if (clock_gettime(CLOCK_MONOTONIC, &spec) != 0) {
        lua_pushnil(L);
        lua_pushstring(L, "Failed to get time");
        return 2;
    }
    
    double time_in_seconds = spec.tv_sec + spec.tv_nsec / 1.0e9;
    
    lua_pushnumber(L, time_in_seconds);
    return 1;
}

static luaL_Reg LIBRARY[] = {
    {"clock", accurate_clock},
    {0}
};

int luaopen_accuratetime(lua_State *L)
{
    luaL_newlib(L, LIBRARY);
    return 1;
}
