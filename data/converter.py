import csv, sys, os

def guess_column_type(column: list[str]) -> tuple[str, type]:
    assert len(column) > 0, "Need data in order to guess the column type"

    try:
        if all(int(s) is not None and int(s) < (1 << 31) for s in column if s != "NULL"): # pyright: ignore[reportUnnecessaryComparison]
            return "INTEGER", int
    except ValueError:
        pass

    try:
        if all(float(s) is not None for s in column if s != "NULL") and any("." in s for s in column if s != "NULL"): # pyright: ignore[reportUnnecessaryComparison]
            return "FLOAT", float
    except ValueError:
        pass

    return "VARCHAR(255)", str

class TableInfo:
    name: str
    columns: list[tuple[str, str]]
    foreign_keys: dict[str, str]
    data: list[dict[str, object]]

    def __init__(self, name: str, columns: list[tuple[str, str]], foreign_keys: dict[str, str], data: list[dict[str, object]]) -> None:
        self.name = name
        self.columns = columns
        self.foreign_keys = foreign_keys
        self.data = data

def get_table_info(file_path: str, weak: bool=False) -> TableInfo | None:
    with open(file_path) as f:
        reader = csv.DictReader(f)
        assert reader.fieldnames is not None
        columns = [x for x in reader.fieldnames]
        data = [row for row in reader]

    table_name = os.path.splitext(os.path.basename(file_path))[0]

    if len(data) == 0:
        return None

    typed_columns: list[tuple[str, str]] = []
    foreign_keys: dict[str, str] = {}
    for i, c in enumerate(columns):
        col_type, converter = guess_column_type([row[c] for row in data])
        
        # Special case, first column is always the ID
        if i == 0 and not weak:
            col_type += " PRIMARY KEY"
            assert c == f"{table_name}ID", f"Table '{file_path}': First 'ID' column must be equal to '<Table Name>ID'"
        typed_columns.append((c, col_type))

        # Save FKs
        if (i != 0 or weak) and c.endswith("ID"):
            foreign_keys[c] = c[:-2]

        # Convert values
        for row in data:
            if row[c] == "NULL":
                row[c] = None
            else:
                row[c] = converter(row[c])

    return TableInfo(table_name, typed_columns, foreign_keys, data)  # pyright: ignore[reportArgumentType]

# Topoligically sort tables such that all of a table's FKs point to tables that exist upon its CREATE TABLE statement
def sort_tables(tables: dict[str, TableInfo]) -> list[tuple[str, TableInfo]]:
    result: list[tuple[str, TableInfo]] = []

    # Find leaves first (and check if the graph of dependencies is cyclical, which would make topo sorting impossible)
    result += ((k, v) for k, v in tables.items() if len(v.foreign_keys) == 0)
    assert len(result) > 0, "Tables are cyclical"

    remaining = set(k for k in tables.keys())
    seen = set(k for k, _ in result)
    remaining.difference_update(seen)

    while remaining:
        # Find tables whose FKs have all been seen before
        next = [k for k in remaining if all(t in seen for t in tables[k].foreign_keys.values())]
        for k in next:
            result.append((k, tables[k]))
            seen.add(k)
        remaining.difference_update(next)

    return result

def value_to_sql(val: object | None, col_type: str) -> str:
    if val is None:
        return "NULL"
    if col_type.startswith("VARCHAR"):
        return f"'{str(val).replace("'", "\\'")}'"
    return str(val)

def main() -> None:
    if len(sys.argv) < 2:
        print(f"Usage: ./{sys.argv[0]} [options] <file1> [options] <file2> ...")
        print("Options:")
        print("\t-w\tWeak entity; has no primary key column")
        sys.exit(1)

    tables: dict[str, TableInfo] = {}
    options: dict[str, bool] = {}

    # Parse tables
    for f in sys.argv[1:]:
        if not os.path.isfile(f):
            if f.startswith("-"):
                f = f[1:]
                if "w" in f:
                    options["weak"] = True
            continue

        info = get_table_info(f, **options)
        options.clear()

        if info is None:
            print(f"-- Failed to get table info for file '{f}'")
            continue

        assert info.name not in tables, "Duplicate table detected"
        tables[info.name] = info

    sorted_tables = sort_tables(tables)

    # Print CREATE TABLE statements
    for name, info in sorted_tables:
        print(f"CREATE TABLE {name}s (")
        print(",\n".join(f"  {c} {t}" for c, t in info.columns), end="")
        if len(info.foreign_keys) > 0:
            print(",")
            print(",\n".join(f"  FOREIGN KEY ({c}) REFERENCES {t}s({c})" for c, t in info.foreign_keys.items()))
        print(");")
        pass

    # Print INSERT INTO statements
    for name, info in sorted_tables:
        for row in info.data:
            print(f"INSERT INTO {name}s VALUES (", end="")
            print(", ".join(value_to_sql(row[c], t) for c, t in info.columns), end="")
            print(");")

if __name__ == "__main__":
    main()
