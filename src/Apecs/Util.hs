{-# LANGUAGE Strict, ScopedTypeVariables, FlexibleContexts, TypeFamilies #-}

module Apecs.Util
  ( EntityCounter, initCounter, nextEntity, newEntity
  ) where

import Apecs.Core
import Apecs.Stores

newtype EntityCounter = EntityCounter Int
instance Component EntityCounter where
  type Storage EntityCounter = Global EntityCounter

initCounter :: IO (Storage EntityCounter)
initCounter = initStore (EntityCounter 0)

{-# INLINE nextEntity #-}
nextEntity :: Has w EntityCounter => System w (Entity ())
nextEntity = do EntityCounter n <- readGlobal
                writeGlobal (EntityCounter (n+1))
                return (Entity n)

{-# INLINE newEntity #-}
newEntity :: (Stores (Storage c) ~ c, Store (Storage c), Has w c, Has w EntityCounter)
          => c -> System w (Entity c)
newEntity c = do ety <- nextEntity
                 set (cast ety) c
                 return (cast ety)
