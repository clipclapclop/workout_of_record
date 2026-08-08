#!/usr/bin/env python3
"""Generate the non-personal SQLite databases used by migration tests."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_DIRECTORY = REPOSITORY_ROOT / "test" / "fixtures" / "database"
SUPPORTED_SCHEMA_VERSIONS = range(8, 14)

BASE_SCHEMA = """
CREATE TABLE movements (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  min_weight REAL,
  weight_delta REAL,
  link TEXT,
  note1 TEXT,
  note2 TEXT,
  muscle_group TEXT NOT NULL,
  sub_muscle_group TEXT,
  is_required_reps INTEGER NOT NULL CHECK (is_required_reps IN (0, 1)),
  is_required_weight INTEGER NOT NULL CHECK (is_required_weight IN (0, 1)),
  is_required_time INTEGER NOT NULL CHECK (is_required_time IN (0, 1)),
  is_required_distance INTEGER NOT NULL DEFAULT 0
    CHECK (is_required_distance IN (0, 1)),
  category TEXT NOT NULL,
  rest_seconds INTEGER,
  UNIQUE (name, muscle_group)
);
CREATE TABLE meso_templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE week_templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  meso_template_id INTEGER NOT NULL REFERENCES meso_templates (id),
  name TEXT NOT NULL,
  workout_count INTEGER NOT NULL
);
CREATE TABLE workout_templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  week_template_id INTEGER NOT NULL REFERENCES week_templates (id),
  name TEXT NOT NULL,
  is_rest_day INTEGER NOT NULL CHECK (is_rest_day IN (0, 1)),
  day_index INTEGER NOT NULL
);
CREATE TABLE exercise_templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  workout_template_id INTEGER NOT NULL REFERENCES workout_templates (id),
  movement_id INTEGER NOT NULL REFERENCES movements (id),
  exercise_index INTEGER NOT NULL
);
CREATE TABLE mesocycles (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  meso_template_id INTEGER NOT NULL REFERENCES meso_templates (id),
  name TEXT NOT NULL,
  total_week_count INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  completed_at INTEGER
);
CREATE TABLE weeks (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  mesocycle_id INTEGER NOT NULL REFERENCES mesocycles (id),
  week_number INTEGER NOT NULL,
  goal TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE (mesocycle_id, week_number)
);
CREATE TABLE workouts (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  week_id INTEGER NOT NULL REFERENCES weeks (id),
  name TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  is_rest_day INTEGER NOT NULL CHECK (is_rest_day IN (0, 1)),
  UNIQUE (week_id, order_index)
);
CREATE TABLE planned_workouts (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  workout_id INTEGER NOT NULL UNIQUE REFERENCES workouts (id)
);
CREATE TABLE completed_workouts (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  workout_id INTEGER NOT NULL UNIQUE REFERENCES workouts (id),
  started_at INTEGER NOT NULL,
  completed_at INTEGER,
  status TEXT NOT NULL,
  skip_reason TEXT
);
CREATE TABLE planned_exercises (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  planned_workout_id INTEGER NOT NULL REFERENCES planned_workouts (id),
  movement_id INTEGER NOT NULL REFERENCES movements (id)
);
CREATE TABLE completed_exercises (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  completed_workout_id INTEGER NOT NULL REFERENCES completed_workouts (id),
  movement_id INTEGER NOT NULL REFERENCES movements (id),
  order_index INTEGER NOT NULL,
  is_persistent INTEGER NOT NULL DEFAULT 1
    CHECK (is_persistent IN (0, 1)),
  skip_reason TEXT,
  UNIQUE (completed_workout_id, order_index)
);
CREATE TABLE planned_sets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  planned_exercise_id INTEGER NOT NULL REFERENCES planned_exercises (id),
  reps INTEGER,
  weight REAL,
  time REAL,
  distance REAL
);
CREATE TABLE completed_sets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  completed_exercise_id INTEGER NOT NULL REFERENCES completed_exercises (id),
  reps INTEGER,
  weight REAL,
  time REAL,
  distance REAL,
  skip_reason TEXT
);
CREATE TABLE pre_workout_checkins (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  workout_id INTEGER NOT NULL UNIQUE REFERENCES workouts (id),
  quads TEXT,
  hamstrings TEXT,
  abs TEXT,
  chest TEXT,
  back TEXT,
  biceps TEXT,
  triceps TEXT,
  traps TEXT,
  forearms TEXT,
  glutes TEXT,
  calves TEXT,
  shoulders TEXT,
  sleep_quality TEXT,
  vim_vigor TEXT,
  mental_state TEXT
);
CREATE TABLE post_exercise_checkins (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  completed_exercise_id INTEGER NOT NULL UNIQUE
    REFERENCES completed_exercises (id),
  joint_pain TEXT NOT NULL
);
CREATE TABLE post_muscle_group_checkins (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  completed_workout_id INTEGER NOT NULL REFERENCES completed_workouts (id),
  muscle_group TEXT NOT NULL,
  effort_level TEXT NOT NULL,
  volume_level TEXT NOT NULL,
  UNIQUE (completed_workout_id, muscle_group)
);
"""


def _add_schema_9(connection: sqlite3.Connection) -> None:
    connection.execute(
        "ALTER TABLE post_muscle_group_checkins "
        "ADD COLUMN pump_level TEXT NOT NULL DEFAULT 'none'"
    )


def _add_schema_10(connection: sqlite3.Connection) -> None:
    # Schema 10 deliberately removed UNIQUE(completed_workout_id, order_index)
    # while replacing is_persistent with persistence. Keep the source fixture
    # unconstrained so it matches the production 9 -> 10 migration.
    connection.executescript(
        """
        CREATE TABLE completed_exercises_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          completed_workout_id INTEGER NOT NULL REFERENCES completed_workouts (id),
          movement_id INTEGER NOT NULL REFERENCES movements (id),
          order_index INTEGER NOT NULL,
          persistence INTEGER NOT NULL DEFAULT 0,
          skip_reason TEXT
        );
        DROP TABLE completed_exercises;
        ALTER TABLE completed_exercises_new RENAME TO completed_exercises;
        """
    )


def _add_schema_11(connection: sqlite3.Connection) -> None:
    connection.execute(
        "ALTER TABLE exercise_templates "
        "ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1 "
        "CHECK (ai_planned IN (0, 1))"
    )
    connection.execute(
        "ALTER TABLE planned_exercises "
        "ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1 "
        "CHECK (ai_planned IN (0, 1))"
    )
    connection.execute(
        "ALTER TABLE completed_exercises "
        "ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1 "
        "CHECK (ai_planned IN (0, 1))"
    )


def _add_schema_12(connection: sqlite3.Connection) -> None:
    connection.execute("ALTER TABLE pre_workout_checkins ADD COLUMN tibialis TEXT")


def _add_schema_13(connection: sqlite3.Connection) -> None:
    connection.execute(
        "ALTER TABLE movements "
        "ADD COLUMN bodyweight_load_fraction REAL NOT NULL DEFAULT 0.0"
    )


SCHEMA_STEPS = {
    9: _add_schema_9,
    10: _add_schema_10,
    11: _add_schema_11,
    12: _add_schema_12,
    13: _add_schema_13,
}


def _insert_fixture_data(connection: sqlite3.Connection, version: int) -> None:
    movement_columns = """
      id, name, min_weight, weight_delta, link, note1, note2, muscle_group,
      sub_muscle_group, is_required_reps, is_required_weight,
      is_required_time, is_required_distance, category, rest_seconds
    """
    movement_values = "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?"
    movements = [
        (1, "Bodyweight Squat", None, None, None, "Built-in fixture", None,
         "quads", None, 1, 0, 0, 0, "resistance", 75),
        (2, "Fixture Carry", 10.0, 5.0, "https://example.invalid/fixture",
         "Synthetic custom movement", "No personal data", "fullBody", "carry",
         0, 1, 1, 1, "resistance", 0),
    ]
    if version >= 13:
        movement_columns += ", bodyweight_load_fraction"
        movement_values += ", ?"
        movements = [movements[0] + (0.85,), movements[1] + (0.35,)]
    connection.executemany(
        f"INSERT INTO movements ({movement_columns}) VALUES ({movement_values})",
        movements,
    )

    connection.executescript(
        """
        INSERT INTO meso_templates (id, name, created_at)
          VALUES (1, 'Fixture Strength Template', 1704067200);
        INSERT INTO week_templates
          (id, meso_template_id, name, workout_count)
          VALUES (1, 1, 'Fixture Week', 2);
        INSERT INTO workout_templates
          (id, week_template_id, name, is_rest_day, day_index)
          VALUES
            (1, 1, 'Fixture Full Body', 0, 0),
            (2, 1, 'Fixture Recovery', 1, 1);
        INSERT INTO mesocycles
          (id, meso_template_id, name, total_week_count, created_at, completed_at)
          VALUES (1, 1, 'Fixture Mesocycle', 4, 1704067200, NULL);
        INSERT INTO weeks
          (id, mesocycle_id, week_number, goal, created_at)
          VALUES (1, 1, 2, 'hard', 1704672000);
        INSERT INTO workouts
          (id, week_id, name, order_index, is_rest_day)
          VALUES
            (1, 1, 'Fixture Full Body', 0, 0),
            (2, 1, 'Fixture Skipped Workout', 1, 0);
        INSERT INTO planned_workouts (id, workout_id) VALUES (1, 1);
        INSERT INTO completed_workouts
          (id, workout_id, started_at, completed_at, status, skip_reason)
          VALUES
            (1, 1, 1704700800, 1704704400, 'completed', NULL),
            (2, 2, 1704787200, 1704787200, 'skipped', 'illness');
        """
    )

    exercise_template_columns = (
        "id, workout_template_id, movement_id, exercise_index"
    )
    exercise_template_values = "1, 1, 1, 0"
    planned_exercise_columns = "id, planned_workout_id, movement_id"
    planned_exercises = [(1, 1, 1), (2, 1, 2)]
    if version >= 11:
        exercise_template_columns += ", ai_planned"
        exercise_template_values += ", 0"
        planned_exercise_columns += ", ai_planned"
        planned_exercises = [(1, 1, 1, 1), (2, 1, 2, 0)]
    connection.execute(
        f"INSERT INTO exercise_templates ({exercise_template_columns}) "
        f"VALUES ({exercise_template_values})"
    )
    connection.executemany(
        f"INSERT INTO planned_exercises ({planned_exercise_columns}) "
        f"VALUES ({', '.join('?' for _ in planned_exercises[0])})",
        planned_exercises,
    )

    if version < 10:
        connection.executemany(
            """
            INSERT INTO completed_exercises
              (id, completed_workout_id, movement_id, order_index,
               is_persistent, skip_reason)
              VALUES (?, 1, ?, ?, ?, ?)
            """,
            [
                (1, 1, 0, 1, None),
                (2, 2, 1, 0, "jointPain"),
                (3, 2, 2, 1, "time"),
            ],
        )
    else:
        completed_columns = (
            "id, completed_workout_id, movement_id, order_index, "
            "persistence, skip_reason"
        )
        completed_rows = [
            (1, 1, 1, 0, 0, None),
            (2, 1, 2, 1, 1, "jointPain"),
            (3, 1, 2, 2, 2, "time"),
        ]
        if version >= 11:
            completed_columns += ", ai_planned"
            completed_rows = [
                completed_rows[0] + (1,),
                completed_rows[1] + (0,),
                completed_rows[2] + (1,),
            ]
        connection.executemany(
            f"INSERT INTO completed_exercises ({completed_columns}) "
            f"VALUES ({', '.join('?' for _ in completed_rows[0])})",
            completed_rows,
        )

    connection.executescript(
        """
        INSERT INTO planned_sets
          (id, planned_exercise_id, reps, weight, time, distance)
          VALUES
            (1, 1, 8, 135.5, NULL, NULL),
            (2, 2, NULL, 52.5, 45.25, 120.75);
        INSERT INTO completed_sets
          (id, completed_exercise_id, reps, weight, time, distance, skip_reason)
          VALUES
            (1, 1, 8, 135.5, NULL, NULL, NULL),
            (2, 1, NULL, NULL, NULL, NULL, 'muscleFatigue'),
            (3, 2, NULL, NULL, NULL, NULL, 'jointPain'),
            (4, 3, NULL, NULL, NULL, NULL, 'time');
        INSERT INTO post_exercise_checkins
          (id, completed_exercise_id, joint_pain)
          VALUES (1, 1, 'aLittle');
        """
    )

    pre_columns = """
      id, workout_id, quads, hamstrings, abs, chest, back, biceps, triceps,
      traps, forearms, glutes, calves, shoulders, sleep_quality, vim_vigor,
      mental_state
    """
    pre_values = [
        1, 1, "some", "none", None, "aLittle", None, None, None, None,
        None, None, None, None, "great", "good", "notGood",
    ]
    if version >= 12:
        pre_columns += ", tibialis"
        pre_values.append("lots")
    connection.execute(
        f"INSERT INTO pre_workout_checkins ({pre_columns}) "
        f"VALUES ({', '.join('?' for _ in pre_values)})",
        pre_values,
    )

    post_columns = (
        "id, completed_workout_id, muscle_group, effort_level, volume_level"
    )
    post_values: list[object] = [1, 1, "quads", "hard", "aLot"]
    if version >= 9:
        post_columns += ", pump_level"
        post_values.append("amazing")
    connection.execute(
        f"INSERT INTO post_muscle_group_checkins ({post_columns}) "
        f"VALUES ({', '.join('?' for _ in post_values)})",
        post_values,
    )


def generate_fixture(version: int) -> Path:
    FIXTURE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    path = FIXTURE_DIRECTORY / f"schema_v{version}.sqlite"
    path.unlink(missing_ok=True)
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA page_size = 4096")
        connection.execute("PRAGMA journal_mode = DELETE")
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(BASE_SCHEMA)
        for target_version in range(9, version + 1):
            SCHEMA_STEPS[target_version](connection)
        _insert_fixture_data(connection, version)
        connection.execute(f"PRAGMA user_version = {version}")
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        if integrity != "ok" or foreign_keys:
            raise RuntimeError(
                f"generated schema {version} is invalid: "
                f"integrity={integrity!r}, foreign_keys={foreign_keys!r}"
            )
        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "versions",
        metavar="VERSION",
        type=int,
        nargs="*",
        help="schema versions to generate (default: every supported version)",
    )
    arguments = parser.parse_args()
    versions = arguments.versions or list(SUPPORTED_SCHEMA_VERSIONS)
    unsupported = sorted(set(versions) - set(SUPPORTED_SCHEMA_VERSIONS))
    if unsupported:
        parser.error(f"unsupported schema versions: {unsupported}")
    for version in versions:
        path = generate_fixture(version)
        print(path.relative_to(REPOSITORY_ROOT))


if __name__ == "__main__":
    main()
