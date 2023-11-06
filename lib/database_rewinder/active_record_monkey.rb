# frozen_string_literal: true

module DatabaseRewinder
  module InsertRecorder
    module Execute
      module NoKwargs
        def execute(sql, *)
          DatabaseRewinder.record_inserted_table self, sql
          super
        end
      end

      module WithKwargs
        def execute(sql, *, **)
          DatabaseRewinder.record_inserted_table self, sql
          super
        end

        def raw_execute(sql, *, **)
          DatabaseRewinder.record_inserted_table self, sql
          super
        end
      end
    end

    module ExecQuery
      module NoKwargs
        def exec_query(sql, *)
          DatabaseRewinder.record_inserted_table self, sql
          super
        end
      end

      module WithKwargs
        def exec_query(sql, *, **)
          DatabaseRewinder.record_inserted_table self, sql
          super
        end
      end
    end

    # This method actually no longer has to be a `prepended` hook because InsertRecorder is a module without a direct method now, but still doing this just for compatibility
    def self.prepended(mod)
      if meth = mod.instance_method(:execute)
        if meth.parameters.any? {|type, _name| [:key, :keyreq, :keyrest].include? type }
          mod.send :prepend, Execute::WithKwargs
        else
          mod.send :prepend, Execute::NoKwargs
        end
      end
      if meth = mod.instance_method(:exec_query)
        if meth.parameters.any? {|type, _name| [:key, :keyreq, :keyrest].include? type }
          mod.send :prepend, ExecQuery::WithKwargs
        else
          mod.send :prepend, ExecQuery::NoKwargs
        end
      end
    end
  end
end


# Already loaded adapters (SQLite3Adapter, PostgreSQLAdapter, AbstractMysqlAdapter, and possibly another third party adapter)
::ActiveRecord::ConnectionAdapters::AbstractAdapter.descendants.each do |adapter|
  # Note: this would only prepend on AbstractMysqlAdapter and not on Mysql2Adapter because ```Mysql2Adapter < InsertRecorder``` becomes true immediately after AbstractMysqlAdapter prepends InsertRecorder
  # Note: In Rails 7.1, there is a possibility of overriding methods in ancestor classes, and it is necessary to ensure overriding in descendant classes, so this condition was removed. Beware of the possibility of being overridden multiple times.
  adapter.send :prepend, DatabaseRewinder::InsertRecorder # unless adapter < DatabaseRewinder::InsertRecorder
end

# Third party adapters that might be loaded in the future
def (::ActiveRecord::ConnectionAdapters::AbstractAdapter).inherited(adapter)
  adapter.send :prepend, DatabaseRewinder::InsertRecorder
end
