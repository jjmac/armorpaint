package arm;

import haxe.Json;
import haxe.io.Bytes;
import kha.Display;
import iron.data.Data;
#if arm_painter
import arm.ui.UISidebar;
import arm.render.Inc;
import arm.sys.Path;
import arm.Enums;
#end

class Config {

	public static var raw: TConfig = null;
	public static var keymap: Dynamic;
	public static var configLoaded = false;

	public static function load(done: Void->Void) {
		try {
			Data.getBlob((Path.isProtected() ? Krom.savePath() : "") + "config.arm", function(blob: kha.Blob) {
				configLoaded = true;
				raw = Json.parse(blob.toString());
				done();
			});
		}
		catch (e: Dynamic) { done(); }
	}

	public static function save() {
		// Use system application data folder
		// when running from protected path like "Program Files"
		var path = (Path.isProtected() ? Krom.savePath() : Path.data() + Path.sep) + "config.arm";
		var bytes = Bytes.ofString(Json.stringify(raw));
		Krom.fileSaveBytes(path, bytes.getData());
	}

	public static function init() {
		if (!configLoaded || raw == null) {
			raw = {};
			raw.locale = "system";
			raw.window_mode = 0;
			raw.window_resizable = true;
			raw.window_minimizable = true;
			raw.window_maximizable = true;
			raw.window_w = 1600;
			raw.window_h = 900;
			raw.window_x = -1;
			raw.window_y = -1;
			raw.window_scale = 1.0;
			raw.window_vsync = true;
			raw.rp_bloom = false;
			raw.rp_gi = false;
			raw.rp_motionblur = false;
			#if (krom_android || krom_ios)
			raw.rp_ssgi = false;
			#else
			raw.rp_ssgi = true;
			#end
			raw.rp_ssr = false;
			raw.rp_supersample = 1.0;
			var disp = Display.primary;
			if (disp != null && disp.width >= 3000 && disp.height >= 2000) {
				raw.window_scale = 2.0;
			}
			#if (krom_android || krom_ios)
			raw.window_scale = 2.0;
			#end
			#if arm_painter
			raw.undo_steps = 4;
			raw.keymap = "default.json";
			#end
		}
		else {
			// Upgrade config format created by older ArmorPaint build
			if (raw.version != Main.version) {
				{
					// Upgrade logic here
					// ...
				}
				raw.version = Main.version;
				save();
			}
		}

		#if arm_painter
		loadKeymap();
		#end
	}

	public static function restore() {
		zui.Zui.Handle.global = new zui.Zui.Handle(); // Reset ui handles
		configLoaded = false;
		init();
		#if arm_painter
		applyConfig();
		#end
	}

	public static inline function getSuperSampleQuality(f: Float): Int {
		return f == 0.25 ? 0 :
			   f == 0.5 ? 1 :
			   f == 1.0 ? 2 :
			   f == 1.5 ? 3 :
			   f == 2.0 ? 4 : 5;
	}

	public static inline function getSuperSampleSize(i: Int): Float {
		return i == 0 ? 0.25 :
			   i == 1 ? 0.5 :
			   i == 2 ? 1.0 :
			   i == 3 ? 1.5 :
			   i == 4 ? 2.0 : 4.0;
	}

	#if arm_painter
	public static function applyConfig() {
		var c = Config.raw;
		c.rp_ssgi = UISidebar.inst.hssgi.selected;
		c.rp_ssr = UISidebar.inst.hssr.selected;
		c.rp_bloom = UISidebar.inst.hbloom.selected;
		c.rp_gi = UISidebar.inst.hvxao.selected;
		c.rp_supersample = getSuperSampleSize(UISidebar.inst.hsupersample.position);
		iron.object.Uniforms.defaultFilter = c.rp_supersample < 1.0 ? kha.graphics4.TextureFilter.PointFilter : kha.graphics4.TextureFilter.LinearFilter;
		save();
		Context.ddirty = 2;

		var current = @:privateAccess kha.graphics4.Graphics2.current;
		if (current != null) current.end();
		Inc.applyConfig();
		if (current != null) current.begin(false);
	}

	public static function loadKeymap() {
		Data.getBlob("keymap_presets/" + raw.keymap, function(blob: kha.Blob) {
			keymap = Json.parse(blob.toString());
		});
	}

	public static function saveKeymap() {
		var path = Data.dataPath + "keymap_presets/" + raw.keymap;
		var bytes = Bytes.ofString(Json.stringify(keymap));
		Krom.fileSaveBytes(path, bytes.getData());
	}

	public static function getTextureRes(): Int {
		var res = App.resHandle.position;
		return res == Res128 ? 128 :
			   res == Res256 ? 256 :
			   res == Res512 ? 512 :
			   res == Res1024 ? 1024 :
			   res == Res2048 ? 2048 :
			   res == Res4096 ? 4096 :
			   res == Res8192 ? 8192 :
			   res == Res16384 ? 16384 : 0;
	}

	public static function getTextureResBias(): Float {
		var res = App.resHandle.position;
		return res == Res128 ? 16.0 :
			   res == Res256 ? 8.0 :
			   res == Res512 ? 4.0 :
			   res == Res1024 ? 2.0 :
			   res == Res2048 ? 1.5 :
			   res == Res4096 ? 1.0 :
			   res == Res8192 ? 0.5 :
			   res == Res16384 ? 0.25 : 1.0;
	}

	public static function getTextureResPos(i: Int): Int {
		return i == 128 ? Res128 :
			   i == 256 ? Res256 :
			   i == 512 ? Res512 :
			   i == 1024 ? Res1024 :
			   i == 2048 ? Res2048 :
			   i == 4096 ? Res4096 :
			   i == 8192 ? Res8192 :
			   i == 16384 ? Res16384 : 0;
	}
	#end
}

typedef TConfig = {
	@:optional var locale: String; // ISO 639-1 locale code or "system" to use the system locale automatically
  // Window
	@:optional var window_mode: Null<Int>; // window, fullscreen
	@:optional var window_w: Null<Int>;
	@:optional var window_h: Null<Int>;
	@:optional var window_x: Null<Int>;
	@:optional var window_y: Null<Int>;
	@:optional var window_resizable: Null<Bool>;
	@:optional var window_maximizable: Null<Bool>;
	@:optional var window_minimizable: Null<Bool>;
	@:optional var window_vsync: Null<Bool>;
	@:optional var window_scale: Null<Float>;
	// Render path
	@:optional var rp_supersample: Null<Float>;
	@:optional var rp_ssgi: Null<Bool>;
	@:optional var rp_ssr: Null<Bool>;
	@:optional var rp_bloom: Null<Bool>;
	@:optional var rp_motionblur: Null<Bool>;
	@:optional var rp_gi: Null<Bool>;
	// Application
	@:optional var version: String; // ArmorPaint version
	@:optional var plugins: Array<String>; // List of enabled plugins
	@:optional var bookmarks: Array<String>; // Bookmarked folders in browser
	@:optional var undo_steps: Null<Int>;	// Number of undo steps to preserve
	@:optional var keymap: String; // Link to keymap file
}
