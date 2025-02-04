import type { Entrypoint, Denops } from "jsr:@denops/std";
import * as std from "jsr:@std/assert";
import * as batch from "jsr:@denops/std/batch";
import * as fn from "jsr:@denops/std/function";
import * as vars from "jsr:@denops/std/variable";
import * as helper from "jsr:@denops/std/helper";
import { assert, ensure, is } from "jsr:@core/unknownutil";
import { delay } from "jsr:@std/async";

function _system_Command(cmd : string[], opt : Deno.CommandOptions) : Deno.Command {
    std.assert(cmd.length > 0);
    const exec = cmd.shift();
    assert(exec, is.String);
    opt.args = cmd;
    return new Deno.Command(exec, opt);
}

interface CommandOutputStringStdout extends Deno.CommandStatus {
    stdout: string,
};
interface CommandOutputStringStderr extends Deno.CommandStatus {
    stderr: string,
};
type CommandOutputString2 = CommandOutputStringStdout & CommandOutputStringStderr

async function system(cmd : string[], opt? : Deno.CommandOptions) : Promise<CommandOutputStringStdout> {
    opt = opt ?? {}
    opt.stdout = "piped";
    const { stdout, ...rest } = await _system_Command(cmd, opt).output();
    return { stdout: new TextDecoder().decode(stdout).trim(), ...rest };
};

async function system2(cmd : string[], opt? : Deno.CommandOptions) : Promise<CommandOutputString2> {
    opt = opt ?? {}
    opt.stdout = "piped"
    opt.stderr = "piped"
    const { stdout, stderr, ...rest } = await _system_Command(cmd, opt).output();
    const td = new TextDecoder()
    return { stdout: td.decode(stdout).trim(), stderr: td.decode(stderr).trim(), ...rest };
};

export const main: Entrypoint = async (denops : Denops) => {
    denops.dispatcher = {
        async PlugUpdate(plugs){
            // buffer messages back to the user so we can echo them one at a time
            let user_messages : string[] = [];

            assert(plugs, is.String);
            const plugs_obj = JSON.parse(plugs);
            const plugins_updated = await Promise.all(Object.keys(plugs_obj).map(async (plugin) => {
                const info = plugs_obj[plugin];
                const git_fetch = await system(["git", "fetch", "--all"], {cwd: info['dir']});
                std.assert(git_fetch.success);
                const git_status = await system(["git", "status", "--porcelain", "-bz"], {cwd: info['dir']});
                std.assert(git_status.success);
                const re = /behind \d+]/;
                if(re.test(git_status.stdout)){
                    const git_pull = await system2(["git", "pull"], {cwd: info["dir"]});
                    if(git_pull.success){
                        if("do" in info){
                            assert(info["do"], is.String);
                            if(info["do"].charAt(0) == ":"){ // execute vimscript, as in vim-plug
                                const result = await fn.execute(denops, info["do"]);
                                // why does result have a leading newline??
                                user_messages.push(`[denops-vim-plug-update] Executing vimscript 'do' hook for plugin '${plugin}' returned: ${result.trim()}`);
                            }
                            else{ // execute system command
                                const cmd = info["do"].split(/\s+/);
                                const { stdout } = await system(cmd, {cwd: ensure(info["dir"], is.String)});
                                user_messages.push(`[denops-vim-plug-update] Executing system 'do' hook for plugin '${plugin}' returned: ${stdout}`);
                            }
                        }
                        return true;
                    }
                    else{
                        await helper.echoerr(denops, `[denops-vim-plug-update] git pull '${info["dir"]}' failed: ${git_pull.stderr}`);
                    }
                }
                return false;
            }));
            for(const msg of user_messages){
                await helper.echo(denops, msg);
                await delay(5000); // give the user a chance to read the message
            }
            return plugins_updated.filter(x => x).length
        },
    };
};
