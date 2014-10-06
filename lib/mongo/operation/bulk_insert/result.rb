# Copyright (C) 2009-2014 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo
  module Operation
    module Write
      class BulkInsert
  
        # Defines custom behaviour of results when inserting.
        #
        # @since 2.0.0
        class Result < Operation::Result

          attr_reader :indexes

          # Gets the number of documents inserted.
          #
          # @example Get the number of documents inserted.
          #   result.n_inserted
          #
          # @return [ Integer ] The number of documents inserted.
          #
          # @since 2.0.0
          def n_inserted
            written_count
          end

          def set_indexes(indexes)
            @indexes = indexes
            self
          end

          def reply_write_errors?(reply)
            reply.documents[0][Operation::ERROR] &&
              reply.documents[0][Operation::ERROR_CODE]
          end

          def aggregate_write_errors
            errors = []
            @replies.map do |reply|
              if write_errors = reply.documents.first['writeErrors']
                errors << write_errors.first.merge('index' => indexes[write_errors.first['index']])
              end
            end
            errors.empty? ? nil : errors
          end
        end

        # Defines custom behaviour of results when inserting.
        # For server versions < 2.5.5 (that don't use write commands).
        #
        # @since 2.0.0
        class LegacyResult < Operation::Result

          attr_reader :indexes

          # Gets the number of documents inserted.
          #
          # @example Get the number of documents inserted.
          #   result.n_inserted
          #
          # @return [ Integer ] The number of documents inserted.
          #
          # @since 2.0.0
          def n_inserted
            return 0 unless acknowledged?
            @replies.reduce(0) do |n, reply|
              n += 1 if reply.documents.first[OK] == 1
              n
            end
          end

          def set_indexes(indexes)
            @indexes = indexes
            self
          end

          def reply_write_errors?(reply)
            reply.documents.first[Operation::ERROR] &&
              reply.documents.first[Operation::ERROR_CODE]
          end

          def aggregate_write_errors
            errors = []
            @replies.each_with_index do |reply, i|
              errors <<  { 'errmsg' => reply.documents[0][Operation::ERROR],
                           'index' => indexes[i],
                           'code' => reply.documents[0][Operation::ERROR_CODE]
                          } if reply_write_errors?(reply)
            end
            errors.empty? ? nil : errors
          end
        end
      end
    end
  end
end
