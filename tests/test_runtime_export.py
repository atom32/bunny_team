"""Dependency tracing tests. Fixtures model syntax; actual exported-game QA is separate."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('runtime_export',ROOT/'tools/runtime_export.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class RuntimeExportTest(unittest.TestCase):
    def test_absent_inventory_remains_resource_tuple(self):
        self.assertIsInstance(MODULE.VERIFY_ABSENT, tuple)
        self.assertEqual(MODULE.VERIFY_ABSENT, ('res://assets/characters/vrm_avatar/avatar_sample_a.glb',))

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name).resolve()
        assert self.root.is_relative_to(Path(tempfile.gettempdir()).resolve())
        self.addCleanup(self.tmp.cleanup)
        self.files = {}
        self.write('scenes/main.tscn','[gd_scene]\n')
        self.write('scripts/main.gd','extends Node\nvar value: Used\nconst MODEL="res://assets/active/model.glb"\n')
        self.write('scripts/used.gd','class_name Used\nextends RefCounted\n')
        self.write('scripts/unused.gd','class_name Unused\nconst MODEL="res://assets/spare/model.glb"\n')
        self.write('assets/active/model.glb','fixture')
        self.write('assets/active/texture.png','fixture')
        self.write('assets/active/LICENSE.txt','Fixture notice, not a real license grant.')
        self.write('assets/spare/model.glb','fixture')
        self.write('resources/content/content_manifest.tres','[gd_resource]\n')
        self.catalog = {'main_scene':'res://scenes/main.tscn','autoloads':[],
                        'classes':[{'class':'Used','path':'res://scripts/used.gd'},{'class':'Unused','path':'res://scripts/unused.gd'}],
                        'dependencies':{'res://scenes/main.tscn':['res://scripts/main.gd'],
                                        'res://assets/active/model.glb':['res://assets/active/texture.png']}}

    def write(self,path,text):
        file = self.root/path;file.parent.mkdir(parents=True,exist_ok=True);file.write_text(text,encoding='utf-8')
        self.files['res://'+path]=file

    def trace(self):
        self.catalog['files']=list(self.files)
        return MODULE.trace(self.root,self.catalog)

    def test_closure_keeps_model_texture_and_global_type(self):
        data=self.trace()
        self.assertIn('res://scripts/used.gd',data['source_sha256'])
        self.assertIn('res://assets/active/model.glb',data['source_sha256'])
        self.assertIn('res://assets/active/texture.png',data['source_sha256'])
        self.assertNotIn('res://assets/spare/model.glb',data['source_sha256'])

    def test_comments_and_ui_strings_do_not_import_unused_classes(self):
        self.write('scripts/main.gd','extends Node\n# Unused\nvar help="Unused"\nvar long_help="""Unused # text"""\n')
        self.assertNotIn('res://scripts/unused.gd',self.trace()['source_sha256'])

    def test_string_paths_survive_comment_characters(self):
        identifiers,strings=MODULE.script_tokens('var x="res://a#b.tres" # Unused\nvar y: Used')
        self.assertNotIn('Unused',identifiers);self.assertIn('Used',identifiers)
        self.assertIn('res://a#b.tres',strings)

    def test_cycles_are_finite(self):
        self.catalog['dependencies']['res://scripts/used.gd']=['res://scripts/main.gd']
        self.assertLess(len(self.trace()['source_sha256']),20)

    def test_existing_developer_scope_is_not_exported(self):
        self.write('scenes/debug/debug.tscn','[gd_scene]\n')
        self.write('scripts/main.gd','const DEBUG="res://scenes/debug/debug.tscn"\n')
        data=self.trace()
        self.assertNotIn('res://scenes/debug/debug.tscn',data['source_sha256'])
        self.assertTrue(data['excluded_existing_developer_references'])

    def test_missing_dependency_fails_loudly(self):
        self.write('scripts/main.gd','const MISSING="res://assets/missing.glb"\n')
        with self.assertRaisesRegex(ValueError,'Missing referenced'):self.trace()

    def test_paths_cannot_escape_the_build_copy(self):
        self.write('scripts/main.gd','const BAD="res://../outside.txt"\n')
        with self.assertRaisesRegex(ValueError,'escapes project'):self.trace()

    def test_full_bound_dynamic_animation_family_is_kept(self):
        self.write('assets/animations/mocap_online_rifle/SomeClip.tres','[gd_resource]\n')
        self.write('scripts/main.gd','const PREFIX="res://assets/animations/mocap_online_rifle/"\n')
        self.assertIn('res://assets/animations/mocap_online_rifle/SomeClip.tres',self.trace()['source_sha256'])

    def test_unreachable_dynamic_family_does_not_force_source_rigs(self):
        self.write('assets/animations/mocap_online_rifle/SomeClip.tres','[gd_resource]\n')
        self.write('assets/animations/mocap_online_rifle/UnusedSource.fbx','fixture')
        self.assertNotIn('res://assets/animations/mocap_online_rifle/UnusedSource.fbx',self.trace()['source_sha256'])
        self.assertNotIn('res://assets/animations/mocap_online_rifle/SomeClip.tres',self.trace()['source_sha256'])

    def test_showcase_is_only_kept_if_referenced_by_runtime(self):
        self.write('scenes/presentation/bunny_master/master_shot.tscn','[gd_scene]\n')
        self.assertNotIn('res://scenes/presentation/bunny_master/master_shot.tscn',self.trace()['source_sha256'])
        self.write('scripts/main.gd','const VIEW="res://scenes/presentation/bunny_master/master_shot.tscn"\n')
        self.assertIn('res://scenes/presentation/bunny_master/master_shot.tscn',self.trace()['source_sha256'])

    def test_shader_include_is_a_dependency_not_a_comment(self):
        self.write('shaders/common.gdshaderinc','uniform float k;')
        self.write('shaders/main.gdshader','#include "res://shaders/common.gdshaderinc"\n')
        self.write('scripts/main.gd','const SHADER="res://shaders/main.gdshader"\n')
        self.assertIn('res://shaders/common.gdshaderinc',self.trace()['source_sha256'])

    def test_all_semicolon_license_paths_are_retained(self):
        self.write('assets/other/LICENSE.txt','Other fixture text')
        self.write('resources/content/content_manifest.tres','license_ref = "res://assets/active/LICENSE.txt; res://assets/other/LICENSE.txt"\n')
        data=self.trace()
        self.assertIn('res://assets/active/LICENSE.txt',data['plain_files'])
        self.assertIn('res://assets/other/LICENSE.txt',data['plain_files'])
        self.assertFalse(data['public_release_approved'])

    def test_companion_license_bundle_survives_without_exporting_spare_model(self):
        self.write('assets/characters/unitychan_battle/animations/idle.fbx','fixture')
        self.write('assets/characters/unitychan_battle/license/Terms.pdf','fixture')
        self.write('scripts/main.gd','const A="res://assets/characters/unitychan_battle/animations/idle.fbx"\n')
        data=self.trace()
        self.assertIn('res://assets/characters/unitychan_battle/license/Terms.pdf',data['companion_license_files'])
        self.assertNotIn('res://assets/spare/model.glb',data['source_sha256'])

    def test_unexpected_review_reference_is_not_silently_dropped(self):
        self.write('assets/characters/vrm_avatar/avatar_sample_a.glb','fixture')
        self.write('scripts/main.gd','const REVIEW="res://assets/characters/vrm_avatar/avatar_sample_a.glb"\n')
        with self.assertRaisesRegex(ValueError,'Unexpected review/rollback'):self.trace()

    def test_exact_preset_preserves_exclusions_and_selects_data(self):
        data=self.trace()
        preset=self.root/'export_presets.cfg'
        preset.write_text('[preset.0]\nexport_filter="all_resources"\ninclude_filter="*.json"\nexclude_filter="tools/*"\n',encoding='utf-8')
        MODULE.apply_preset(preset,data);text=preset.read_text(encoding='utf-8')
        self.assertIn('export_filter="resources"',text);self.assertIn('export_files=PackedStringArray(',text)
        self.assertIn('exclude_filter="tools/*"',text);self.assertNotIn('include_filter="res://',text)


if __name__=='__main__':unittest.main()
